# frozen_string_literal: true

require 'spec_helper'

# The single live, read-only smoke test. It hits a real Dolibarr instance only when
# both DOLIBARR_BASE_URL and DOLAPIKEY are set, and self-skips otherwise (so CI and
# offline runs stay green). It never writes: a lone GET of at most one invoice.
RSpec.describe 'live read-only smoke', :smoke do
  before do
    skip 'set DOLIBARR_BASE_URL and DOLAPIKEY to run the live smoke test' unless
      ENV['DOLIBARR_BASE_URL'] && ENV['DOLAPIKEY']
  end

  let(:client) do
    Dolibarr::Client.new(base_url: "#{ENV.fetch('DOLIBARR_BASE_URL')}/api/index.php", token: ENV.fetch('DOLAPIKEY'))
  end

  it 'lists invoices without raising (empty instance normalises to [])' do
    invoices = client.invoices.list(limit: 1)

    expect(invoices).to be_an(Array)
    expect(invoices.size).to be <= 1
    expect(invoices).to all(be_a(Dolibarr::Invoice))
  end

  # Regression guard for the `mode` translation: Dolibarr answers HTTP 400 when the
  # raw label "customer" is passed instead of the integer code 1. Bounded to one row
  # to stay a lightweight, read-only GET (same translation path as #all).
  it 'lists customers by business mode without raising a 400' do
    customers = client.thirdparties.list(mode: 'customer', limit: 1)

    expect(customers).to be_an(Array)
    expect(customers.size).to be <= 1
    expect(customers).to all(be_a(Dolibarr::Thirdparty))
  end
end
