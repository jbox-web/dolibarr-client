# frozen_string_literal: true

require 'simplecov'
require 'simplecov_json_formatter'

# Start SimpleCov
SimpleCov.start do
  formatter SimpleCov::Formatter::MultiFormatter.new([SimpleCov::Formatter::HTMLFormatter, SimpleCov::Formatter::JSONFormatter])
  add_filter 'spec/'
end

# Configure RSpec
RSpec.configure do |config|
  config.color = true
  config.fail_fast = false

  config.order = :random
  Kernel.srand config.seed

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  # The end-to-end suite (tag :e2e) spins up a dockerized Dolibarr and writes to it.
  # It is opt-in: excluded from the default run unless DOLIBARR_E2E is set (the
  # `rake spec:e2e` task sets it). This keeps `rspec`/`rake` network-free and write-free.
  config.filter_run_excluding(:e2e) unless ENV['DOLIBARR_E2E']

  # disable monkey patching
  # see: https://relishapp.com/rspec/rspec-core/v/3-8/docs/configuration/zero-monkey-patching-mode
  config.disable_monkey_patching!

  config.raise_errors_for_deprecations!
end

require 'dolibarr-client'
