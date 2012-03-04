if RUBY_VERSION =~ /1.9/ then
  require 'simplecov'
  SimpleCov.start 'test_frameworks'
else
  require 'rcov'
end

require 'rantly/property'
require 'rspec'
require 'zipr'

require 'zipr/rantly-extensions'
require 'zipr/test-trees'
