# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Dolibarr::Client do
  let(:base_url) { 'https://erp.example.com/api/index.php' }
  let(:token)    { 'secret-key' }

  describe '#initialize' do
    it 'accepts explicit configuration' do
      client = described_class.new(base_url: base_url, token: token)

      expect(client.base_url).to eq base_url
    end

    it 'reads configuration from the environment by default' do
      stub_const('ENV', ENV.to_h.merge(described_class::ENV_BASE_URL => base_url, described_class::ENV_TOKEN => token))

      expect(described_class.new.base_url).to eq base_url
    end

    it 'raises Dolibarr::Client::Error when the base URL is missing' do
      expect { described_class.new(base_url: nil, token: token) }
        .to raise_error(Dolibarr::Client::Error, include(described_class::ENV_BASE_URL))
    end

    it 'raises Dolibarr::Client::Error when the token is missing' do
      expect { described_class.new(base_url: base_url, token: '') }
        .to raise_error(Dolibarr::Client::Error, include(described_class::ENV_TOKEN))
    end

    it 'isolates configuration between instances (multi-instance, no global state)' do
      a = described_class.new(base_url: 'https://a.example.com/api/index.php', token: 'a')
      b = described_class.new(base_url: 'https://b.example.com/api/index.php', token: 'b')

      expect(a.base_url).not_to eq b.base_url
    end
  end

  describe '#transport' do
    subject(:client) { described_class.new(base_url: base_url, token: token) }

    it 'builds a memoised dolibarr-api client passing the token as api_key' do
      allow(Dolibarr::Api::Client).to receive(:new).and_call_original

      expect(client.transport).to be_a(Dolibarr::Api::Client)
      client.transport # second call must be served from the memo

      expect(Dolibarr::Api::Client).to have_received(:new)
        .with(base_url: base_url, api_key: token).once
    end

    it 'isolates the transport between instances' do
      a = described_class.new(base_url: 'https://a.example.com/api/index.php', token: 'a')
      b = described_class.new(base_url: 'https://b.example.com/api/index.php', token: 'b')

      expect(a.transport).not_to be b.transport
    end
  end

  describe '#connection' do
    subject(:client) { described_class.new(base_url: base_url, token: token) }

    it 'exposes the transport connection' do
      expect(client.connection).to be client.transport.connection
    end
  end

  describe 'domain accessors' do
    subject(:client) { described_class.new(base_url: base_url, token: token) }

    {
      invoices:           Dolibarr::Invoices,
      payments:           Dolibarr::Payments,
      thirdparties:       Dolibarr::Thirdparties,
      documents:          Dolibarr::Documents,
      supplier_invoices:  Dolibarr::SupplierInvoices,
      recurring_invoices: Dolibarr::RecurringInvoices,
    }.each do |name, klass|
      it "exposes ##{name} as a memoised #{klass}" do
        domain = client.public_send(name)

        expect(domain).to be_a(klass)
        expect(client.public_send(name)).to be domain
      end
    end
  end
end
