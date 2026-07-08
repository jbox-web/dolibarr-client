# frozen_string_literal: true

module Dolibarr
  # @return [Gem::Version] the gem version
  def self.gem_version
    Gem::Version.new VERSION::STRING
  end

  # Gem version components.
  module VERSION
    # Major version component.
    # @api private
    MAJOR = 0
    # Minor version component.
    # @api private
    MINOR = 1
    # Patch version component.
    # @api private
    TINY  = 0
    # Pre-release tag (e.g. "beta"), or nil for a final release.
    # @api private
    PRE   = nil

    # @return [String] the dotted version string, e.g. "0.1.0"
    STRING = [MAJOR, MINOR, TINY, PRE].compact.join('.')
  end
end
