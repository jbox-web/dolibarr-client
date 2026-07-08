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
end
