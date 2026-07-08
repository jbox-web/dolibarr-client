# frozen_string_literal: true

source 'https://rubygems.org'

gemspec

# Transport layer, built in parallel. While it is unpublished, reference it here.
# Swap `path:` for `github:` when working without a local checkout:
#
#   gem 'dolibarr-api', github: 'jbox-web/dolibarr-api'
gem 'dolibarr-api', path: '../dolibarr-api'

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
