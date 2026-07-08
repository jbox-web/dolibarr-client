# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Dolibarr::Thirdparty do
  subject(:thirdparty) { described_class.from('id' => '42', 'name' => 'ACME Corp', 'ref' => 'CU-42') }

  it 'exposes id, name and ref' do
    expect(thirdparty.id).to eq '42'
    expect(thirdparty.name).to eq 'ACME Corp'
    expect(thirdparty.ref).to eq 'CU-42'
  end
end
