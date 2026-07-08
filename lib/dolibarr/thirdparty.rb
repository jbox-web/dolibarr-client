# frozen_string_literal: true

module Dolibarr
  # A thirdparty (customer or supplier). Every field stays reachable via {Record#raw} /
  # {Record#[]}; the common ones get named readers.
  class Thirdparty < Record
    # @return [String, nil] the company / thirdparty name
    def name
      self['name']
    end

    # @return [String, nil] the thirdparty reference, when set
    def ref
      self['ref']
    end
  end
end
