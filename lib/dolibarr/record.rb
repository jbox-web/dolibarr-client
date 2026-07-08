# frozen_string_literal: true

module Dolibarr
  # Base for the gem's value objects (Invoice, Payment, Thirdparty). A thin, read-only
  # view over a normalised response hash: amounts are already coerced to BigDecimal by
  # {Coerce} at construction, string keys are preserved, and the full payload stays
  # reachable through {#raw} / {#[]} so nothing the API returned is ever hidden.
  class Record
    # @return [Hash] the normalised (amount-coerced) payload
    attr_reader :raw

    # Build from a raw parsed response hash, coercing amounts.
    # @param hash [Hash]
    def self.from(hash)
      new(Coerce.amounts(hash))
    end

    def initialize(raw)
      @raw = raw || {}
    end

    # Read any field by its Dolibarr key.
    # @param key [String, Symbol]
    def [](key)
      raw[key.to_s]
    end

    # @return [String, nil] the object id (Dolibarr returns it as a string)
    def id
      self['id']
    end

    # Two records are equal when they are the same class and wrap the same payload.
    # @param other [Object]
    # @return [Boolean]
    def ==(other)
      other.is_a?(self.class) && raw == other.raw
    end
    alias eql? ==

    # @return [Integer] a hash consistent with {#==}, so records key Hashes / Sets correctly
    def hash
      raw.hash
    end

    # @return [Hash] the normalised payload
    def to_h
      raw
    end
  end
end
