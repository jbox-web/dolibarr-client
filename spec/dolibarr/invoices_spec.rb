# frozen_string_literal: true

require 'spec_helper'
require 'date'

RSpec.describe Dolibarr::Invoices do
  let(:connection) { instance_double(Dolibarr::Api::Connection) }
  let(:client)     { instance_double(Dolibarr::Client, connection: connection) }
  let(:invoices)   { described_class.new(client) }

  def resp(data) = instance_double(Dolibarr::Api::Response, data: data)
  def api_error(status) = Dolibarr::Api::ApiError.new(status: status)

  describe '#list' do
    it 'returns Invoice value objects' do
      allow(connection).to receive(:call).and_return(resp([{ 'id' => '1', 'ref' => 'FA-1' }]))

      result = invoices.list

      expect(result).to all(be_a(Dolibarr::Invoice))
      expect(result.first.ref).to eq 'FA-1'
    end

    it 'normalises the empty-list 404 to []' do
      allow(connection).to receive(:call).and_raise(api_error(404))

      expect(invoices.list).to eq []
    end

    it 'maps paid: true to the "paid" status filter' do
      allow(connection).to receive(:call).and_return(resp([]))

      invoices.list(paid: true)

      expect(connection).to have_received(:call).with(
        :GET, '/invoices', hash_including(query: hash_including('status' => 'paid'))
      )
    end

    it 'maps paid: false to the "unpaid" status filter' do
      allow(connection).to receive(:call).and_return(resp([]))

      invoices.list(paid: false)

      expect(connection).to have_received(:call).with(
        :GET, '/invoices', hash_including(query: hash_including('status' => 'unpaid'))
      )
    end

    it 'builds a period sqlfilter from :from and :to (accepts Date or String)' do
      allow(connection).to receive(:call).and_return(resp([]))

      invoices.list(from: Date.new(2026, 1, 1), to: '2026-01-31')

      expect(connection).to have_received(:call).with(
        :GET, '/invoices',
        hash_including(query: hash_including(
          'sqlfilters' => "(t.datef:>=:'2026-01-01') and (t.datef:<=:'2026-01-31')"
        ))
      )
    end

    it 'passes the thirdparty filter through' do
      allow(connection).to receive(:call).and_return(resp([]))

      invoices.list(thirdparty_id: 42)

      expect(connection).to have_received(:call).with(
        :GET, '/invoices', hash_including(query: hash_including('thirdparty_ids' => 42))
      )
    end
  end

  describe '#all / #each (transparent pagination)' do
    it 'walks pages until a short page' do
      allow(connection).to receive(:call).and_return(
        resp([{ 'id' => '1' }, { 'id' => '2' }]),
        resp([{ 'id' => '3' }])
      )

      ids = invoices.all(limit: 2).map(&:id)

      expect(ids).to eq %w[1 2 3]
      expect(connection).to have_received(:call).twice
    end

    it '#each without a block returns an Enumerator' do
      allow(connection).to receive(:call).and_return(resp([]))

      expect(invoices.each).to be_a(Enumerator)
    end
  end

  describe '#find' do
    it 'fetches by ref via /invoices/ref/{ref} with type: nil' do
      allow(connection).to receive(:call).and_return(resp({ 'id' => '7', 'ref' => 'FA-7' }))

      invoice = invoices.find(ref: 'FA-7')

      expect(invoice).to be_a(Dolibarr::Invoice)
      expect(connection).to have_received(:call).with(
        :GET, '/invoices/ref/FA-7', hash_including(type: nil, auth: ['api_key'])
      )
    end

    it 'fetches by id via /invoices/{id}' do
      allow(connection).to receive(:call).and_return(resp({ 'id' => '7' }))

      invoices.find(id: 7)

      expect(connection).to have_received(:call).with(
        :GET, '/invoices/7', hash_including(type: nil)
      )
    end

    it 'raises ArgumentError unless exactly one of ref/id is given' do
      expect { invoices.find }.to raise_error(ArgumentError)
      expect { invoices.find(ref: 'x', id: 1) }.to raise_error(ArgumentError)
    end

    it 'maps a 404 to NotFound (not an empty list)' do
      allow(connection).to receive(:call).and_raise(api_error(404))

      expect { invoices.find(ref: 'nope') }.to raise_error(Dolibarr::Client::NotFound, /invoice/)
    end
  end

  describe '#create' do
    it 'POSTs the attributes as the body and returns the new id' do
      allow(connection).to receive(:call).and_return(resp(123))

      id = invoices.create(socid: 42, type: 0, lines: [])

      expect(id).to eq 123
      expect(connection).to have_received(:call).with(
        :POST, '/invoices', hash_including(body: { socid: 42, type: 0, lines: [] })
      )
    end
  end

  describe '#validate' do
    it 'POSTs to /invoices/{id}/validate and returns the refreshed Invoice' do
      allow(connection).to receive(:call).and_return(resp({ 'id' => '7', 'statut' => '1' }))

      invoice = invoices.validate(id: 7)

      expect(invoice).to be_a(Dolibarr::Invoice)
      expect(connection).to have_received(:call).with(
        :POST, '/invoices/7/validate', hash_including(type: nil)
      )
    end
  end
end
