require 'rubygems'
require 'rake'
require 'rspec/core/rake_task'

# Uses:
# rubygems
# rake
# rantly
# rspec

require 'rake/testtask'
RSpec::Core::RakeTask.new(:test) do |test|
  test.pattern = 'test/**/e*_test.rb'
  test.verbose = true
end

task :default => :test
