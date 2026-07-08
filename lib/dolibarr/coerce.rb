# frozen_string_literal: true

require 'bigdecimal'

module Dolibarr
  # Restler serialises every amount as a string ("8900.00000000"). This absorbs that
  # quirk: it deep-walks a parsed response and turns money-typed string fields into
  # {BigDecimal} (never Float — accounting arithmetic must stay exact). Detection is
  # by key, not by value, so an all-digits identifier (a `socid`, a phone number)
  # under a non-money key is never mistaken for an amount.
  module Coerce
    # Keys whose value is a monetary amount: money-ish prefixes (`total…`, `montant…`,
    # `amount…`, `remain…`, `deposit…`) and money-ish suffixes (`…_ht`, `…_ttc`, `…_tva`,
    # `…_vat`, `…_pu`, `…_localtax`). Deliberately excludes `paye`/`paid`, which Dolibarr
    # uses as 0/1 flags, not amounts.
    AMOUNT_KEY = /
      \A(?:total|montant|amount|remain|deposit)
      | _(?:ht|ttc|tva|vat|pu|localtax\d*)\z
    /xi

    # A plain decimal string, optionally signed. Guards against coercing free text
    # ("N/A", "") that Dolibarr sometimes returns in a money field.
    NUMERIC = /\A-?\d+(?:\.\d+)?\z/

    # Deep-walk `obj`, returning a copy with every money-keyed numeric string coerced
    # to BigDecimal. Hashes and arrays are traversed; scalars pass through.
    #
    # @param obj [Object] a parsed JSON value (Hash, Array, or scalar)
    # @return [Object] the same shape with amounts coerced
    def self.amounts(obj)
      case obj
      when Array
        obj.map { |v| amounts(v) }
      when Hash
        obj.each_with_object({}) do |(key, value), out|
          out[key] = amount?(key, value) ? BigDecimal(value) : amounts(value)
        end
      else
        obj
      end
    end

    # @return [Boolean] whether `value` under `key` is a coercible monetary amount
    def self.amount?(key, value)
      value.is_a?(String) && key.to_s.match?(AMOUNT_KEY) && value.match?(NUMERIC)
    end
    private_class_method :amount?
  end
end
