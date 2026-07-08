# frozen_string_literal: true

source 'https://rubygems.org'

gemspec

# Transport layer, built in parallel and not yet published to RubyGems. Use a local
# sibling checkout when it exists (fast local dev), otherwise fetch from GitHub — this is
# what CI and any clone without the sibling get. Gemfile.lock is gitignored, so the two
# sources resolve independently and never clash.
dolibarr_api_path = File.expand_path('../dolibarr-api', __dir__)
if File.directory?(dolibarr_api_path)
  gem 'dolibarr-api', path: dolibarr_api_path
else
  gem 'dolibarr-api', github: 'jbox-web/dolibarr-api'
end

# Dev libs
# irb is only needed for bin/console; scope it to MRI so it does not drag rdoc
# -> rbs (a native extension that fails to build on JRuby) into the bundle.
gem 'irb', platforms: :mri
gem 'rake'
gem 'rspec'
gem 'simplecov'
gem 'simplecov_json_formatter'

# Dev tools / linter
gem 'guard-rspec',         require: false
gem 'rubocop',             require: false
gem 'rubocop-performance', require: false
gem 'rubocop-rake',        require: false
gem 'rubocop-rspec',       require: false
gem 'yard',                require: false
