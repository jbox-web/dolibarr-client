# frozen_string_literal: true

require 'spec_helper'
require 'bigdecimal'

RSpec.describe Dolibarr::Payment do
  subject(:payment) do
    described_class.from('amount' => '8900.00', 'type' => 'VIR', 'date' => '2026-01-31', 'ref' => 'PAY-1')
  end

  it 'exposes fields and coerces the amount' do
    expect(payment.amount).to eql BigDecimal('8900.00')
    expect(payment.type).to eq 'VIR'
    expect(payment.date).to eq '2026-01-31'
    expect(payment.ref).to eq 'PAY-1'
  end
end
