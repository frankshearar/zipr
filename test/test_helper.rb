if RUBY_VERSION =~ /1.8/ then
  require 'rcov'
else
  require 'simplecov'
  SimpleCov.start 'test_frameworks'
  require 'coveralls'
  Coveralls.wear!
end

require 'rantly/property'
require 'rspec'
require 'sexp'
require 'zipr'

require 'zipr/rantly-extensions'
require 'zipr/test-trees'
