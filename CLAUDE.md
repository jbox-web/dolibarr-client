# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Role

You are an expert Ruby developer: meticulous, precise, and exhaustive. Favor idiomatic, well-tested code, handle edge cases, and never cut corners.

You always work in TDD: write a failing test first, watch it fail, then write the minimal code to make it pass, then refactor. No production code without a failing test first.

## Overview

`dolibarr-client` is an idiomatic, business-oriented Ruby wrapper over the Dolibarr REST API (Dolibarr 23.x, powered by Restler). It is a thin, hand-written layer on top of the [`dolibarr-api`](https://github.com/jbox-web/dolibarr-api) transport gem, exposing a monthly-billing working set (invoices, payments, thirdparties, documents, supplier invoices) and absorbing Restler quirks so they never reach the caller.

## Commands

Use the committed **binstubs** in `bin/` (run the tools directly, no `bundle exec`). Regenerate them after `bundle install` with `bundle binstubs rspec-core rubocop rake`.

```bash
bin/rspec                                # run the full test suite
bin/rspec spec/dolibarr/client_spec.rb   # run one file
bin/rubocop                              # lint (must pass in CI)
bin/rubocop -a                           # auto-correct safe offenses
bin/rake                                 # default task == spec
bin/rake spec:e2e                        # opt-in end-to-end suite (needs Docker)
bin/yard                                 # generate YARD API docs into doc/ (reads .yardopts)
```

Mise tasks mirror these for CI/scripts: `mise dev:deps`, `mise dev:spec`, `mise dev:e2e`, `mise dev:docs`. The `docs` workflow (`.github/workflows/docs.yml`) runs `mise dev:docs` on push to `master` and publishes `doc/` to [GitHub Pages](https://jbox-web.github.io/dolibarr-client/).

CI (`.github/workflows/ci.yml`) runs RuboCop on Ruby 3.4 and RSpec across Ruby 3.0–4.0, JRuby, and TruffleRuby. `required_ruby_version` is `>= 3.0.0`.

## Architecture

- **Autoloading via Zeitwerk** (`lib/dolibarr.rb`). The gem entry `dolibarr-client` (dash) requires `dolibarr` (no dash); the dash file is `ignore`d by the loader and excluded from RuboCop. Add classes under `lib/dolibarr/` and they autoload by convention — no manual `require`.
- **`Dolibarr::Client`** (`lib/dolibarr/client.rb`) is the public entry. One instance targets one Dolibarr instance (multi-instance, no global singleton). Config (`base_url`, `token`) defaults from `ENV["DOLIBARR_BASE_URL"]` / `ENV["DOLAPIKEY"]`. It lazily builds the transport (`#transport` → `Dolibarr::Api::Client.new(base_url:, api_key: token)`), exposes `#connection`, and memoises one domain object per accessor: `invoices`, `payments`, `thirdparties`, `documents`, `supplier_invoices`, `recurring_invoices`.
- **Domains inherit `Dolibarr::Resource`** (`lib/dolibarr/resource.rb`), which owns the shared plumbing: reaching `connection`, error translation (`collection`→404-list-to-`[]`; `one`→404-to-`NotFound`; `call`→write), `paginate` (transparent 0-based pagination), and `get_list`/`get_one` helpers. **Reads go through `connection.call(..., type: nil)`**, never the transport's typed `get`s: those pin the placeholder `Models::Obj` (a Restler formatter-config model with no `additional_properties`) which silently drops the real payload. Nested transport sub-clients (`Invoices::Ref`/`Templates`/`Payments`, `Supplierinvoices::Payments`) are not exposed by the transport `Client`, so domains hit their raw paths directly.
- **Value objects** `Dolibarr::Invoice` / `Payment` / `Thirdparty` (base `Dolibarr::Record`, `lib/dolibarr/record.rb`) wrap a normalised payload (amounts already coerced); the full hash stays reachable via `#raw` / `#[]`. Supplier and recurring invoices return normalised hashes, not value objects.
- **Single error surface**: `Dolibarr::Client::Error` (`lib/dolibarr/client/error.rb`), with `NotFound` and `Forbidden` subclasses (own files, per Zeitwerk). Every failure — config, business validation, or a wrapped `dolibarr-api` transport error — is raised as (a subclass of) this, with the transport error preserved as `#cause`.

## Restler quirks to absorb (invisible to the caller)

- **Empty list = HTTP 404** → normalize to `[]`, never an error (list endpoints only; a 404 on a single object by id/ref raises `Dolibarr::Client::NotFound`).
- **403** (missing rights) → `Dolibarr::Client::Forbidden` with an explicit, actionable message.
- **Amounts as strings** (`"8900.00000000"`) → coerce to `BigDecimal` (exact, never `Float`; `Dolibarr::Coerce.amounts` detects money by key, not value). `bigdecimal` and `base64` are runtime deps (no longer default gems on Ruby ≥ 3.4).
- **Pagination** (`limit`/`page`/`sortfield` e.g. `t.rowid`/`sortorder`) → hidden behind ergonomic iteration (`#each`/`#all` auto-paginate; raw `page:`/`limit:` still available on `#list`).

## Testing

Unit specs run without network. The transport (`dolibarr-api`) is mocked/injected. One read-only smoke test hits a live instance when `DOLIBARR_BASE_URL` + `DOLAPIKEY` are set, and self-skips otherwise. The default `rspec`/`rake` run is network-free and write-free.

An **opt-in** end-to-end suite (`spec/e2e`, tag `:e2e`, excluded from the default run unless `DOLIBARR_E2E` is set — `rake spec:e2e` sets it) boots a **disposable** dockerized Dolibarr (`docker-compose.e2e.yml`) and exercises the real write cycle (create → validate → pay/close → download PDF). It writes only to that throwaway instance and owns its own compose lifecycle (`up` → seed → `down -v`). A dedicated CI job runs it on one Ruby, separate from the cross-Ruby matrix. Key facts for that setup:
- **MariaDB, not PostgreSQL**: the `dolibarr/dolibarr` image only auto-installs the schema on MySQL/MariaDB (entrypoint gates DB init on `DB_TYPE != pgsql`). Backend is irrelevant to what the suite checks.
- **Module enablement is not pure SQL**: a raw `MAIN_MODULE_*` const insert leaves `llx_rights_def` empty → 403 for everyone. Modules are enabled via Dolibarr's native `activateModule()` (`spec/e2e/support/enable_modules.php`); only the `api_key` is seeded via SQL.
- Prerequisites (thirdparty, bank account) are created through the raw transport in the spec; the wrapper is the system under test.

## Status

Business wrapper implemented against `dolibarr-api` 0.1.0 (referenced via `path:`/`github:` until it is published to RubyGems). All domains are wired and covered by network-free unit specs; the read-only smoke test passes against the live instance (invoices, thirdparties, payments, empty-list normalisation, amount coercion, and the `type: nil` bypass all verified in real conditions). Recurring/template invoices are **read-only by design** — Dolibarr 23.0.3 exposes no REST write for templates. See the [reference gem `ovh-rest`](https://github.com/jbox-web/ovh-rest) for the house style.
