# frozen_string_literal: true

require 'spec_helper'
require 'bigdecimal'

RSpec.describe Dolibarr::Invoice do
  subject(:invoice) do
    described_class.from(
      'id'          => '123',
      'ref'         => 'FA2601-0007',
      'socid'       => '42',
      'total_ht'    => '7416.67',
      'total_tva'   => '1483.33',
      'total_ttc'   => '8900.00',
      'remaintopay' => '0.00000000',
      'paye'        => '1'
    )
  end

  it 'exposes core fields' do
    expect(invoice.id).to eq '123'
    expect(invoice.ref).to eq 'FA2601-0007'
    expect(invoice.socid).to eq '42'
  end

  it 'coerces amounts to BigDecimal via Coerce' do
    expect(invoice.total_ht).to eql BigDecimal('7416.67')
    expect(invoice.total_tva).to eql BigDecimal('1483.33')
    expect(invoice.total_ttc).to eql BigDecimal('8900.00')
    expect(invoice.remaining_to_pay).to eql BigDecimal('0')
  end

  it 'exposes the normalised payload via #to_h and hashes by payload' do
    expect(invoice.to_h).to eq invoice.raw
    expect(invoice.hash).to eq described_class.from(invoice.raw).hash
  end

  it 'reads the paid flag' do
    expect(invoice).to be_paid
    expect(described_class.from('paye' => '0')).not_to be_paid
  end

  it 'keeps the full normalised payload on #raw and #[]' do
    expect(invoice['ref']).to eq 'FA2601-0007'
    expect(invoice.raw).to be_a(Hash)
  end

  it 'compares by payload' do
    twin = described_class.from('id' => '1')

    expect(described_class.from('id' => '1')).to eq twin
  end
end
