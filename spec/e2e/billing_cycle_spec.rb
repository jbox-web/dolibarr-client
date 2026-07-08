# frozen_string_literal: true

require 'spec_helper'
require 'date'
require 'bigdecimal'
require 'tmpdir'
require 'fileutils'
require_relative 'support/instance'

# Full monthly billing cycle against a disposable dockerized Dolibarr 23.0.3.
#
# Opt-in only (`:e2e`, excluded from the default run — see spec_helper); driven by
# `rake spec:e2e`. It WRITES, so it runs exclusively against the throwaway instance
# `Instance` spins up and tears down. Prerequisites (thirdparty, bank account) are
# created through the raw transport; the wrapper is the system under test.
RSpec.describe 'billing cycle', :e2e do
  before(:all) do
    E2E::Instance.up
    client = E2E::Instance.client
    transport = client.transport

    socid = transport.thirdparties.create(
      create_thirdparties_model: { 'name' => 'E2E Client', 'client' => 1, 'country_id' => 1 }
    ).data
    account = transport.bankaccounts.create(
      create_bankaccounts_model: {
        'ref' => 'E2E', 'label' => 'E2E Bank', 'type' => 1, 'country_id' => 1,
        'currency_code' => 'EUR', 'bank' => 'E2E',
      }
    ).data

    # --- system under test: the wrapper ---
    id = client.invoices.create(
      socid: socid, type: 0, date: Date.today.strftime('%Y-%m-%d'),
      lines: [{ 'desc' => 'E2E line', 'subprice' => 100, 'qty' => 1, 'tva_tx' => 20 }]
    )
    client.invoices.validate(id: id)
    @invoice = client.invoices.find(id: id)

    client.payments.register(invoice_id: id, account_id: account, payment_mode_id: 2, close: true)
    @settled = client.invoices.find(id: id)

    # Build the PDF (a write, via transport), then exercise the wrapper's download.
    transport.documents.builddoc(
      documents_builddoc_model: {
        'modulepart' => 'facture', 'original_file' => "#{@invoice.ref}/#{@invoice.ref}.pdf",
        'doctemplate' => 'sponge', 'langcode' => 'en_US',
      }
    )
    @pdf_dir = Dir.mktmpdir('e2e-pdf')
    @pdf_path = File.join(@pdf_dir, "#{@invoice.ref}.pdf")
    client.documents.download_invoice_pdf(ref: @invoice.ref, to: @pdf_path)
  end

  after(:all) do
    FileUtils.remove_entry(@pdf_dir) if @pdf_dir && File.directory?(@pdf_dir)
    E2E::Instance.down
  end

  it 'creates and validates an invoice, assigning a real ref' do
    expect(@invoice.ref).to be_a(String)
    expect(@invoice.ref).not_to be_empty
  end

  it 'coerces the invoice amount to BigDecimal' do
    expect(@invoice.total_ttc).to be_a(BigDecimal)
    expect(@invoice.total_ttc).to eq BigDecimal('120')
  end

  it 'settles the remaining balance and closes the invoice' do
    expect(@settled).to be_paid
    expect(@settled.remaining_to_pay).to eq BigDecimal('0')
  end

  it 'downloads the invoice PDF to disk' do
    expect(File.size(@pdf_path)).to be > 0
    expect(File.binread(@pdf_path, 5)).to eq '%PDF-'
  end
end
