# frozen_string_literal: true

require_relative 'lib/dolibarr/version'

Gem::Specification.new do |s|
  s.name        = 'dolibarr-client'
  s.version     = Dolibarr::VERSION::STRING
  s.platform    = Gem::Platform::RUBY
  s.authors     = ['Nicolas Rodriguez']
  s.email       = ['nico@nicoladmin.fr']
  s.homepage    = 'https://github.com/jbox-web/dolibarr-client'
  s.summary     = 'Idiomatic, business-oriented Dolibarr client'
  s.description = 'A thin, hand-written business wrapper over the dolibarr-api transport layer.'
  s.license     = 'MIT'

  s.required_ruby_version = '>= 3.0.0'

  s.files = Dir['README.md', 'CHANGELOG.md', 'LICENSE', 'lib/**/*.rb']

  # Transport layer. The source is supplied by the Gemfile (path:/github:) until
  # dolibarr-api is published to RubyGems; the constraint stays loose (`>= 0.1`)
  # meanwhile and is tightened to `~> 0.1` on first release.
  s.add_dependency 'dolibarr-api', '>= 0.1'
  # Amounts arrive as strings ("8900.00000000"); coerce them to BigDecimal, not Float,
  # to keep accounting arithmetic exact. Bundled-but-not-default since Ruby 3.4.
  s.add_dependency 'bigdecimal'
  # Invoice PDFs come back base64-encoded in a JSON envelope; decode them on download.
  # Bundled-but-not-default since Ruby 3.4.
  s.add_dependency 'base64'
  s.add_dependency 'zeitwerk'
end
