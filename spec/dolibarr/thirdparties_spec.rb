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

  describe '#list mode translation' do
    before { allow(connection).to receive(:call).and_return(resp([])) }

    # Dolibarr's `mode` filter is an integer (api_thirdparties.class.php@23.0.3):
    # 1=customers, 2=prospects, 4=suppliers. The wrapper exposes readable values.
    { 'customer' => 1, 'prospect' => 2, 'supplier' => 4 }.each do |value, code|
      it "maps the string #{value.inspect} to Dolibarr code #{code}" do
        thirdparties.list(mode: value)

        expect(connection).to have_received(:call).with(
          :GET, '/thirdparties', hash_including(query: hash_including('mode' => code))
        )
      end

      it "maps the symbol :#{value} to Dolibarr code #{code}" do
        thirdparties.list(mode: value.to_sym)

        expect(connection).to have_received(:call).with(
          :GET, '/thirdparties', hash_including(query: hash_including('mode' => code))
        )
      end
    end

    it 'raises a clear error on an unknown mode, never sending it to the API' do
      expect { thirdparties.list(mode: 'ghost') }
        .to raise_error(Dolibarr::Client::Error, /unknown thirdparty mode.*ghost.*customer.*prospect.*supplier/i)

      expect(connection).not_to have_received(:call)
    end

    it 'leaves an absent mode untouched (unfiltered list still works)' do
      thirdparties.list

      expect(connection).to have_received(:call).with(
        :GET, '/thirdparties', hash_including(query: hash_including('mode' => nil))
      )
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
