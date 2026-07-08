# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Dolibarr::Resource do
  # A minimal concrete subclass that exposes the protected helpers so their behaviour
  # can be exercised in isolation from any real domain.
  let(:subclass) do
    Class.new(described_class) do
      def run_collection(&block) = collection(&block)
      def run_one(what, &block) = one(what, &block)
      def run_call(&block) = call(&block)
      def conn = connection
    end
  end

  let(:connection) { instance_double(Dolibarr::Api::Connection) }
  let(:client)     { instance_double(Dolibarr::Client, connection: connection) }
  let(:resource)   { subclass.new(client) }

  def api_error(status)
    Dolibarr::Api::ApiError.new(status: status)
  end

  describe '#connection' do
    it 'delegates to the client transport connection' do
      expect(resource.conn).to be connection
    end
  end

  describe 'collection (list semantics)' do
    it 'returns the yielded list on success' do
      expect(resource.run_collection { [1, 2] }).to eq [1, 2]
    end

    it 'normalises an empty-list 404 to []' do
      expect(resource.run_collection { raise api_error(404) }).to eq []
    end

    it 'maps 403 to Dolibarr::Client::Forbidden with an actionable message' do
      expect { resource.run_collection { raise api_error(403) } }
        .to raise_error(Dolibarr::Client::Forbidden, /permission|rights/i)
    end

    it 'wraps any other transport error as Error, preserving the cause' do
      expect { resource.run_collection { raise api_error(500) } }
        .to raise_error(Dolibarr::Client::Error) { |e| expect(e.cause).to be_a(Dolibarr::Api::ApiError) }
    end
  end

  describe 'one (single-object semantics)' do
    it 'returns the yielded object on success' do
      expect(resource.run_one('invoice') { { 'id' => '1' } }).to eq('id' => '1')
    end

    it 'maps 404 to Dolibarr::Client::NotFound naming the record' do
      expect { resource.run_one('invoice') { raise api_error(404) } }
        .to raise_error(Dolibarr::Client::NotFound, /invoice not found/)
    end

    it 'maps 403 to Forbidden' do
      expect { resource.run_one('invoice') { raise api_error(403) } }
        .to raise_error(Dolibarr::Client::Forbidden)
    end
  end

  describe 'call (write semantics)' do
    it 'returns the yielded value on success' do
      expect(resource.run_call { 99 }).to eq 99
    end

    it 'wraps a transport error as Error, preserving the cause' do
      expect { resource.run_call { raise api_error(500) } }
        .to raise_error(Dolibarr::Client::Error) { |e| expect(e.cause).to be_a(Dolibarr::Api::ApiError) }
    end
  end

  describe '#paginate' do
    it 'walks pages until a short page and yields every item flattened' do
      pages = { 0 => [1, 2], 1 => [3] } # limit 2: page 1 is short -> stop
      items = resource.send(:paginate, limit: 2) { |page, _limit| pages.fetch(page, []) }

      expect(items.to_a).to eq [1, 2, 3]
    end

    it 'stops on the first empty page' do
      items = resource.send(:paginate, limit: 2) { |_page, _limit| [] }

      expect(items.to_a).to eq []
    end
  end
end
