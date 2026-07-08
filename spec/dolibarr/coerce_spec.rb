# frozen_string_literal: true

require 'spec_helper'
require 'bigdecimal'

RSpec.describe Dolibarr::Coerce do
  describe '.amounts' do
    it 'coerces amount-like string fields to BigDecimal' do
      result = described_class.amounts('total_ttc' => '8900.00000000')

      expect(result['total_ttc']).to eql BigDecimal('8900.00000000')
    end

    it 'coerces every recognised money key (ht, tva, ttc, remaintopay, ...)' do
      raw = {
        'total_ht'    => '7416.67',
        'total_tva'   => '1483.33',
        'total_ttc'   => '8900.00',
        'remaintopay' => '0.00',
      }

      result = described_class.amounts(raw)

      expect(result.values).to all(be_a(BigDecimal))
    end

    it 'leaves non-amount string fields untouched (ref, socid, phone)' do
      raw = { 'ref' => 'FA2601-0007', 'socid' => '42', 'phone' => '0102030405' }

      expect(described_class.amounts(raw)).to eq raw
    end

    it 'does not coerce non-numeric strings even under an amount key' do
      expect(described_class.amounts('total_ttc' => 'N/A')).to eq('total_ttc' => 'N/A')
    end

    it 'walks nested hashes and arrays' do
      raw = { 'lines' => [{ 'total_ttc' => '10.00', 'label' => 'x' }] }

      result = described_class.amounts(raw)

      expect(result['lines'].first['total_ttc']).to eql BigDecimal('10.00')
      expect(result['lines'].first['label']).to eq 'x'
    end

    it 'passes through non-collection values' do
      expect(described_class.amounts(nil)).to be_nil
      expect(described_class.amounts('plain')).to eq 'plain'
    end
  end
end
