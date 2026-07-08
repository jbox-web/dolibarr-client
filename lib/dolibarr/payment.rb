# frozen_string_literal: true

module Dolibarr
  # A payment recorded against an invoice. The `amount` is BigDecimal; the rest of the
  # Dolibarr payload stays reachable via {Record#raw} / {Record#[]}.
  class Payment < Record
    # @return [BigDecimal, nil] the paid amount
    def amount
      self['amount']
    end

    # @return [String, nil] the payment mode label/code (e.g. "VIR", "CHQ")
    def type
      self['type']
    end

    # @return [String, nil] the payment date as returned by Dolibarr
    def date
      self['date']
    end

    # @return [String, nil] the payment reference, when present
    def ref
      self['ref']
    end
  end
end
