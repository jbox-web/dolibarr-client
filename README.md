# dolibarr-client

[![CI](https://github.com/jbox-web/dolibarr-client/actions/workflows/ci.yml/badge.svg)](https://github.com/jbox-web/dolibarr-client/actions/workflows/ci.yml)
[![docs](https://github.com/jbox-web/dolibarr-client/actions/workflows/docs.yml/badge.svg)](https://jbox-web.github.io/dolibarr-client/)
[![License](https://img.shields.io/github/license/jbox-web/dolibarr-client)](LICENSE)

Idiomatic, business-oriented [Dolibarr](https://www.dolibarr.org) client for Ruby — a
thin, hand-written wrapper over [`dolibarr-api`](https://github.com/jbox-web/dolibarr-api)
(the HTTP transport layer). It exposes exactly the monthly billing working set —
customer invoices, payments, recurring invoices, thirdparties, documents, supplier
invoices — and absorbs Dolibarr's Restler quirks so they never reach your code.

> **Restler quirks absorbed here:** an empty list comes back as HTTP 404 → normalized
> to `[]`; monetary amounts arrive as strings (`"8900.00000000"`) → coerced to
> `BigDecimal` (exact, never `Float`); pagination (`limit`/`page`/`sortfield`/`sortorder`)
> is hidden behind ergonomic iteration; every failure surfaces as a single
> `Dolibarr::Client::Error` (the transport error is preserved as `#cause`), a missing
> object raises `Dolibarr::Client::NotFound`, and a 403 raises `Dolibarr::Client::Forbidden`
> with an actionable message.

## Installation

Add to your `Gemfile`. Until both gems are published to RubyGems, reference the
transport (`dolibarr-api`) from git as well — it is a runtime dependency and Bundler
cannot fetch it from RubyGems yet:

```ruby
gem 'dolibarr-client', github: 'jbox-web/dolibarr-client'
gem 'dolibarr-api',    github: 'jbox-web/dolibarr-api'
```

Then run `bundle install`.

## Configuration

Credentials and endpoint are read from the environment by default and can be
overridden per instance. **Never commit them** — pass them through the environment.

| Variable            | Meaning                                                        |
| ------------------- | ------------------------------------------------------------- |
| `DOLIBARR_BASE_URL` | API base, e.g. `https://erp.example.com/api/index.php`        |
| `DOLAPIKEY`         | API key (handed to the transport as `api_key`)                |

```ruby
require 'dolibarr-client'

# From the environment (DOLIBARR_BASE_URL + DOLAPIKEY):
dolibarr = Dolibarr::Client.new

# Or explicitly (multi-instance friendly — no global singleton):
dolibarr = Dolibarr::Client.new(
  base_url: "https://erp.example.com/api/index.php",
  token:    ENV.fetch("DOLAPIKEY"),
)
```

## Usage

```ruby
require 'dolibarr-client'
require 'date'

dolibarr = Dolibarr::Client.new   # from ENV
```

### Customer invoices

```ruby
# One page (business filters + raw pagination); returns Dolibarr::Invoice objects.
dolibarr.invoices.list(paid: false, from: Date.new(2026, 1, 1), to: Date.new(2026, 1, 31))

# Every match, paginating transparently (Enumerator without a block).
dolibarr.invoices.all(thirdparty_id: 42)
dolibarr.invoices.each { |invoice| puts invoice.ref }

invoice = dolibarr.invoices.find(ref: 'FA2601-0007')   # or find(id: 123)
invoice.total_ttc   # => BigDecimal("8900.00000000")
invoice.paid?       # => false

id = dolibarr.invoices.create(socid: 42, type: 0, lines: [{ desc: 'Hosting', subprice: 100, qty: 1 }])
dolibarr.invoices.validate(id: id)
```

### Payments

Dolibarr's per-invoice payment settles the **full remaining balance** and can close the
invoice in the same call:

```ruby
# Pay the remaining balance and classify the invoice as paid, in one call.
dolibarr.payments.register(invoice_id: invoice.id, account_id: 1, payment_mode_id: 2)

# Register without closing:
dolibarr.payments.register(invoice_id: invoice.id, account_id: 1, payment_mode_id: 2, close: false)

dolibarr.payments.for_invoice(invoice_id: invoice.id)   # => [Dolibarr::Payment]
```

### Thirdparties

```ruby
dolibarr.thirdparties.find(id: 42).name
dolibarr.thirdparties.all(mode: 'customer')
```

### Documents

```ruby
# Download a customer invoice PDF (must already be generated in Dolibarr) to a path.
dolibarr.documents.download_invoice_pdf(ref: 'FA2601-0007', to: '/tmp/FA2601-0007.pdf')
```

### Supplier invoices (read-only)

```ruby
dolibarr.supplier_invoices.list(limit: 20)   # => [Hash] (amounts coerced to BigDecimal)
dolibarr.supplier_invoices.find(id: 5)
```

### Recurring / template invoices (read-only)

```ruby
dolibarr.recurring_invoices.all   # => [Hash]
dolibarr.recurring_invoices.find(id: 3)
```

> **Recurring invoices are read-only by design.** Dolibarr 23.0.3 exposes no REST
> endpoint to create a template or trigger a generation — that happens in the Dolibarr
> UI or its internal cron. The invoices it generates surface in the ordinary
> `invoices` domain, where the full validate → pay → close cycle lives.

### Error handling

Every failure is a `Dolibarr::Client::Error` (or a subclass), with the underlying
transport error kept as `#cause`:

```ruby
begin
  dolibarr.invoices.find(ref: 'DOES-NOT-EXIST')
rescue Dolibarr::Client::NotFound => e   # 404 on a single object
  warn e.message
rescue Dolibarr::Client::Forbidden => e  # 403 missing rights
  warn e.message
rescue Dolibarr::Client::Error => e      # anything else
  warn "#{e.message} (caused by #{e.cause.class})"
end
```

## Development

Committed **binstubs** (`bin/`) run the tools directly — no `bundle exec` prefix:

```bash
mise install     # provision Ruby (see mise.toml)
bundle install   # regenerate binstubs after this with: bundle binstubs rspec-core rubocop rake yard
bin/rspec        # run the test suite
bin/rubocop      # lint
bin/rake         # default task == spec
bin/yard         # generate API docs into doc/ (reads .yardopts)
```

API documentation is generated with YARD (`bin/yard` or `mise dev:docs`) and published to
[GitHub Pages](https://jbox-web.github.io/dolibarr-client/) on every push to `master` by the
[docs workflow](.github/workflows/docs.yml).

The default suite is **network-free and write-free**: the transport is mocked. A single
**read-only** smoke test runs against a live instance when `DOLIBARR_BASE_URL` and
`DOLAPIKEY` are set in the environment; it self-skips otherwise.

### End-to-end suite (opt-in)

```bash
bin/rake spec:e2e   # requires Docker
```

This spins up a **disposable** Dolibarr 23.0.3 (MariaDB + `dolibarr:23.0.3`) via
[`docker-compose.e2e.yml`](docker-compose.e2e.yml), auto-installs and seeds it, then
exercises the real write cycle — create → validate → register payment/close → download
PDF — and tears everything down (`down -v`). It is excluded from the default `rspec`/`rake`
run and from the cross-Ruby CI matrix; a dedicated CI job runs it on one Ruby. It writes
**only** to that throwaway instance, never to a real one.

> MariaDB, not PostgreSQL: the official `dolibarr/dolibarr` image only auto-installs the
> schema on MySQL/MariaDB. The DB backend is irrelevant to what the suite checks (the
> wrapper against a live REST API); production stays on PostgreSQL.

## License

[MIT](LICENSE) — Nicolas Rodriguez.
