# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- Project skeleton: gemspec, Zeitwerk bootstrap, `Dolibarr::Client` configuration
  (env-driven `base_url`/`token`), single error surface `Dolibarr::Client::Error`,
  RSpec suite, RuboCop, CI.
- Business wrapper over the `dolibarr-api` transport: domain accessors on
  `Dolibarr::Client` (`invoices`, `payments`, `thirdparties`, `documents`,
  `supplier_invoices`, `recurring_invoices`).
- `Dolibarr::Invoices`: `list`/`each`/`all` (filter by period, thirdparty, paid/unpaid;
  transparent pagination), `find(ref:|id:)`, `create`, `validate`.
- `Dolibarr::Payments`: `register` (settle the remaining balance and optionally close
  the invoice in one call) and `for_invoice`.
- `Dolibarr::Thirdparties`, `Dolibarr::SupplierInvoices` (read-only) and
  `Dolibarr::RecurringInvoices` (read-only — Dolibarr 23.0.3 exposes no template write).
- `Dolibarr::Documents#download_invoice_pdf`: fetch and decode an invoice PDF to a path.
- Value objects `Dolibarr::Invoice`, `Dolibarr::Payment`, `Dolibarr::Thirdparty` over a
  normalised payload.
- Restler quirks absorbed: empty-list 404 → `[]`, string amounts → `BigDecimal`,
  403 → `Dolibarr::Client::Forbidden`, single-object 404 → `Dolibarr::Client::NotFound`;
  transport errors wrapped as `Dolibarr::Client::Error` with `#cause` preserved.
