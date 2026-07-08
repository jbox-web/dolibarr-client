# frozen_string_literal: true

require 'spec_helper'
require 'date'
require 'bigdecimal'

RSpec.describe Dolibarr::Payments do
  let(:connection) { instance_double(Dolibarr::Api::Connection) }
  let(:client)     { instance_double(Dolibarr::Client, connection: connection) }
  let(:payments)   { described_class.new(client) }

  def resp(data) = instance_double(Dolibarr::Api::Response, data: data)
  def api_error(status) = Dolibarr::Api::ApiError.new(status: status)

  describe '#for_invoice' do
    it 'returns Payment value objects with coerced amounts' do
      allow(connection).to receive(:call).and_return(resp([{ 'amount' => '8900.00', 'type' => 'VIR' }]))

      result = payments.for_invoice(invoice_id: 7)

      expect(result).to all(be_a(Dolibarr::Payment))
      expect(result.first.amount).to eql BigDecimal('8900.00')
      expect(connection).to have_received(:call).with(:GET, '/invoices/7/payments', anything)
    end

    it 'returns [] when the invoice has no payment (404)' do
      allow(connection).to receive(:call).and_raise(api_error(404))

      expect(payments.for_invoice(invoice_id: 7)).to eq []
    end
  end

  describe '#register' do
    it 'pays the full remaining amount and closes the invoice in one call' do
      allow(connection).to receive(:call).and_return(resp(555))

      id = payments.register(invoice_id: 7, account_id: 1, payment_mode_id: 2, date: Date.new(2026, 1, 31))

      expect(id).to eq 555
      expect(connection).to have_received(:call).with(
        :POST, '/invoices/7/payments',
        hash_including(body: {
          'accountid' => 1, 'paymentid' => 2,
          'datepaye' => '2026-01-31', 'closepaidinvoices' => 'yes',
        })
      )
    end

    it 'can register without closing (close: false)' do
      allow(connection).to receive(:call).and_return(resp(556))

      payments.register(invoice_id: 7, account_id: 1, payment_mode_id: 2, date: '2026-01-31', close: false)

      expect(connection).to have_received(:call).with(
        :POST, '/invoices/7/payments',
        hash_including(body: hash_including('closepaidinvoices' => 'no'))
      )
    end

    it 'includes optional number and comment when given, omitting nils' do
      allow(connection).to receive(:call).and_return(resp(557))

      payments.register(invoice_id: 7, account_id: 1, payment_mode_id: 2,
                        date: '2026-01-31', number: 'VIR-42', comment: 'January')

      expect(connection).to have_received(:call).with(
        :POST, '/invoices/7/payments',
        hash_including(body: hash_including('num_payment' => 'VIR-42', 'comment' => 'January'))
      )
    end

    it 'surfaces a 403 as Forbidden' do
      allow(connection).to receive(:call).and_raise(api_error(403))

      expect { payments.register(invoice_id: 7, account_id: 1, payment_mode_id: 2) }
        .to raise_error(Dolibarr::Client::Forbidden)
    end
  end
end
