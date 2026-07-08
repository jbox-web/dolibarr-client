# frozen_string_literal: true

# require ruby dependencies
require 'json'

# require external dependencies
require 'zeitwerk'

# Transport layer this wrapper is built on. Requiring it here makes `Dolibarr::Api`
# available to every domain and lets callers `require "dolibarr-client"` alone.
require 'dolibarr-api'

# load zeitwerk
Zeitwerk::Loader.for_gem.tap do |loader|
  loader.ignore("#{__dir__}/dolibarr-client.rb")
  loader.setup
end

# Idiomatic, business-oriented Ruby wrapper over the Dolibarr REST API. It sits on
# top of the {https://github.com/jbox-web/dolibarr-api dolibarr-api} transport layer
# and absorbs Restler's quirks (empty-list 404s, string amounts, pagination) behind a
# stable, ergonomic surface. See {Dolibarr::Client}.
module Dolibarr
  # Convenience shortcut for {Dolibarr::Client#initialize Dolibarr::Client.new}.
  #
  # @return [Dolibarr::Client]
  def self.new(...)
    Client.new(...)
  end
end
