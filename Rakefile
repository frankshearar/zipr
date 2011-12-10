require 'rubygems'
require 'rubygems/package_task'
require 'rake'
require 'rspec/core/rake_task'
require 'rake/clean'
require 'rake/testtask'

CLEAN.include('pkg')

RSpec::Core::RakeTask.new(:test) do |test|
  test.pattern = 'test/**/*_test.rb'
  test.verbose = true
end

gemspec = eval(File.open(File.expand_path('./zipr.gemspec')) {|f| f.read})
Gem::PackageTask.new(gemspec) do |pkg|
  pkg.need_zip = true
  pkg.need_tar = true
end

task :default => :install

task :install => [:clean, :test, :package] do
  sh "gem install pkg/#{gemspec.name}-#{gemspec.version}"
end
