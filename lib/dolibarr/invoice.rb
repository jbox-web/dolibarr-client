# frozen_string_literal: true

module Dolibarr
  # A customer invoice. Amounts are BigDecimal; every other field stays reachable via
  # {Record#raw} / {Record#[]}.
  class Invoice < Record
    # @return [String, nil] the invoice reference (e.g. "FA2601-0007")
    def ref
      self['ref']
    end

    # @return [String, nil] the thirdparty (customer) id
    def socid
      self['socid']
    end

    # @return [BigDecimal, nil] total excluding tax
    def total_ht
      self['total_ht']
    end

    # @return [BigDecimal, nil] total tax
    def total_tva
      self['total_tva']
    end

    # @return [BigDecimal, nil] total including tax
    def total_ttc
      self['total_ttc']
    end

    # @return [BigDecimal, nil] amount still due
    def remaining_to_pay
      self['remaintopay']
    end

    # @return [Boolean] whether Dolibarr flags the invoice as paid (`paye == 1`)
    def paid?
      self['paye'].to_s == '1'
    end
  end
end
