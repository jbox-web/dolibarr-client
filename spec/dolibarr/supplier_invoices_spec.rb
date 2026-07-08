# frozen_string_literal: true

require 'spec_helper'
require 'bigdecimal'

RSpec.describe Dolibarr::SupplierInvoices do
  let(:connection) { instance_double(Dolibarr::Api::Connection) }
  let(:client)     { instance_double(Dolibarr::Client, connection: connection) }
  let(:suppliers)  { described_class.new(client) }

  def resp(data) = instance_double(Dolibarr::Api::Response, data: data)
  def api_error(status) = Dolibarr::Api::ApiError.new(status: status)

  describe '#list' do
    it 'returns normalised hashes with coerced amounts' do
      allow(connection).to receive(:call).and_return(resp([{ 'ref' => 'SI-1', 'total_ttc' => '120.00' }]))

      result = suppliers.list

      expect(result.first['total_ttc']).to eql BigDecimal('120.00')
      expect(connection).to have_received(:call).with(:GET, '/supplierinvoices', anything)
    end

    it 'normalises an empty list (404) to []' do
      allow(connection).to receive(:call).and_raise(api_error(404))

      expect(suppliers.list).to eq []
    end
  end

  describe '#all' do
    it 'paginates transparently' do
      allow(connection).to receive(:call).and_return(
        resp([{ 'ref' => 'SI-1' }, { 'ref' => 'SI-2' }]), resp([{ 'ref' => 'SI-3' }])
      )

      expect(suppliers.all(limit: 2).map { |h| h['ref'] }).to eq %w[SI-1 SI-2 SI-3]
    end
  end

  describe '#find' do
    it 'fetches by id via /supplierinvoices/{id} and coerces amounts' do
      allow(connection).to receive(:call).and_return(resp({ 'ref' => 'SI-1', 'total_ht' => '100.00' }))

      result = suppliers.find(id: 5)

      expect(result['total_ht']).to eql BigDecimal('100.00')
      expect(connection).to have_received(:call).with(:GET, '/supplierinvoices/5', hash_including(type: nil))
    end

    it 'maps 404 to NotFound' do
      allow(connection).to receive(:call).and_raise(api_error(404))

      expect { suppliers.find(id: 5) }.to raise_error(Dolibarr::Client::NotFound, /supplier invoice/)
    end
  end
end
