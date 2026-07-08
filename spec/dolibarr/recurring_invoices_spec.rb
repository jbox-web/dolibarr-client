# frozen_string_literal: true

require 'spec_helper'
require 'bigdecimal'

RSpec.describe Dolibarr::RecurringInvoices do
  let(:connection) { instance_double(Dolibarr::Api::Connection) }
  let(:client)     { instance_double(Dolibarr::Client, connection: connection) }
  let(:recurring)  { described_class.new(client) }

  def resp(data) = instance_double(Dolibarr::Api::Response, data: data)
  def api_error(status) = Dolibarr::Api::ApiError.new(status: status)

  describe '#list' do
    it 'lists template invoices via /invoices/templates with coerced amounts' do
      allow(connection).to receive(:call).and_return(resp([{ 'ref' => 'MODEL-1', 'total_ttc' => '99.00' }]))

      result = recurring.list

      expect(result.first['total_ttc']).to eql BigDecimal('99.00')
      expect(connection).to have_received(:call).with(:GET, '/invoices/templates', anything)
    end

    it 'normalises an empty list (404) to []' do
      allow(connection).to receive(:call).and_raise(api_error(404))

      expect(recurring.list).to eq []
    end
  end

  describe '#all' do
    it 'paginates transparently' do
      allow(connection).to receive(:call).and_return(
        resp([{ 'ref' => 'M-1' }, { 'ref' => 'M-2' }]), resp([{ 'ref' => 'M-3' }])
      )

      expect(recurring.all(limit: 2).map { |h| h['ref'] }).to eq %w[M-1 M-2 M-3]
    end
  end

  describe '#find' do
    it 'fetches a template by id via /invoices/templates/{id}' do
      allow(connection).to receive(:call).and_return(resp({ 'ref' => 'MODEL-1' }))

      recurring.find(id: 3)

      expect(connection).to have_received(:call).with(:GET, '/invoices/templates/3', hash_including(type: nil))
    end

    it 'maps 404 to NotFound' do
      allow(connection).to receive(:call).and_raise(api_error(404))

      expect { recurring.find(id: 3) }.to raise_error(Dolibarr::Client::NotFound, /template/)
    end
  end
end
