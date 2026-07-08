# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Dolibarr do
  describe '.new' do
    it 'builds a configured client' do
      client = described_class.new(base_url: 'https://erp.example.com/api/index.php', token: 'tok')

      expect(client).to be_a(Dolibarr::Client)
      expect(client.base_url).to eq 'https://erp.example.com/api/index.php'
    end
  end

  describe '.gem_version' do
    it 'returns the gem version' do
      expect(described_class.gem_version).to be_a(Gem::Version)
      expect(described_class.gem_version.to_s).to eq Dolibarr::VERSION::STRING
    end
  end

  describe 'error hierarchy' do
    it 'exposes a single error surface under Dolibarr::Client::Error' do
      expect(Dolibarr::Client::Error.ancestors).to include(StandardError)
    end
  end
end
