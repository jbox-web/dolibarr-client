# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Dolibarr::Thirdparties do
  let(:connection)   { instance_double(Dolibarr::Api::Connection) }
  let(:client)       { instance_double(Dolibarr::Client, connection: connection) }
  let(:thirdparties) { described_class.new(client) }

  def resp(data) = instance_double(Dolibarr::Api::Response, data: data)
  def api_error(status) = Dolibarr::Api::ApiError.new(status: status)

  describe '#list' do
    it 'returns Thirdparty value objects' do
      allow(connection).to receive(:call).and_return(resp([{ 'id' => '42', 'name' => 'ACME' }]))

      result = thirdparties.list

      expect(result).to all(be_a(Dolibarr::Thirdparty))
      expect(result.first.name).to eq 'ACME'
      expect(connection).to have_received(:call).with(:GET, '/thirdparties', anything)
    end

    it 'normalises an empty list (404) to []' do
      allow(connection).to receive(:call).and_raise(api_error(404))

      expect(thirdparties.list).to eq []
    end
  end

  describe '#all' do
    it 'paginates transparently' do
      allow(connection).to receive(:call).and_return(
        resp([{ 'id' => '1' }, { 'id' => '2' }]), resp([{ 'id' => '3' }])
      )

      expect(thirdparties.all(limit: 2).map(&:id)).to eq %w[1 2 3]
    end
  end

  describe '#find' do
    it 'fetches by id via /thirdparties/{id} with type: nil' do
      allow(connection).to receive(:call).and_return(resp({ 'id' => '42', 'name' => 'ACME' }))

      thirdparty = thirdparties.find(id: 42)

      expect(thirdparty).to be_a(Dolibarr::Thirdparty)
      expect(connection).to have_received(:call).with(:GET, '/thirdparties/42', hash_including(type: nil))
    end

    it 'maps 404 to NotFound' do
      allow(connection).to receive(:call).and_raise(api_error(404))

      expect { thirdparties.find(id: 999) }.to raise_error(Dolibarr::Client::NotFound, /thirdparty/)
    end
  end
end
