# frozen_string_literal: true

require 'date'

module Dolibarr
  # Payments recorded against customer invoices.
  #
  # Dolibarr's per-invoice payment endpoint settles the *full remaining amount* (there
  # is no partial-amount field) and can close the invoice in the same call via
  # `closepaidinvoices`. {#register} exposes exactly that: pay and close in one shot.
  class Payments < Resource
    # The payments already recorded on an invoice.
    #
    # @param invoice_id [Integer, String]
    # @return [Array<Payment>] empty when the invoice has none
    def for_invoice(invoice_id:)
      get_list("/invoices/#{encode(invoice_id)}/payments").map { |raw| Payment.from(raw) }
    end

    # Record a payment on an invoice, settling its remaining balance, and (by default)
    # close it.
    #
    # @param invoice_id [Integer, String] the invoice to pay
    # @param account_id [Integer] the bank account receiving the payment
    # @param payment_mode_id [Integer] the payment mode id (transfer, cheque, …)
    # @param date [Date, String] the payment date (defaults to today)
    # @param close [Boolean] classify the invoice as paid in the same call (default true)
    # @param number [String, nil] payment number (cheque/transfer ref), optional
    # @param comment [String, nil] private note, optional
    # @return [Integer] the id of the created payment
    def register(invoice_id:, account_id:, payment_mode_id:, date: Date.today,
                 close: true, number: nil, comment: nil)
      body = {
        'accountid'         => account_id,
        'paymentid'         => payment_mode_id,
        'datepaye'          => iso_date(date),
        'closepaidinvoices' => close ? 'yes' : 'no',
        'num_payment'       => number,
        'comment'           => comment,
      }.compact

      call do
        connection.call(
          :POST, "/invoices/#{encode(invoice_id)}/payments",
          type: nil, auth: ['api_key'], body: body
        ).data
      end
    end
  end
end
