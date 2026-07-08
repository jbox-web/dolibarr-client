# frozen_string_literal: true

require 'bundler/gem_tasks'
require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new(:spec)
task default: :spec

namespace :spec do
  desc 'Run the opt-in end-to-end suite against a disposable dockerized Dolibarr'
  task :e2e do
    ENV['DOLIBARR_E2E'] = '1'
    sh 'bundle exec rspec spec/e2e'
  end
end
