require 'rubygems'
require 'rubygems/package_task'
require 'rake'
require 'rspec/core/rake_task'
require 'rake/clean'
require 'rake/testtask'
require 'rcov'
require 'rcov/rcovtask'

CLEAN.include('pkg')

RSpec::Core::RakeTask.new(:test) do |test|
  test.pattern = 'test/test*.rb'
  test.verbose = true
end

RSpec::Core::RakeTask.new(:stress_test) do |test|
  test.pattern = 'test/*_stresstest.rb'
  test.verbose = true
end

gemspec = eval(File.open(File.expand_path('./zipr.gemspec')) {|f| f.read})
Gem::PackageTask.new(gemspec) do |pkg|
  pkg.need_zip = true
  pkg.need_tar = true
end

task :default => :install

task :stress_test

task :install => [:clean, :test, :package] do
  sh "gem install pkg/#{gemspec.name}-#{gemspec.version}"
end

task :coverage => [:test, :rcov]

Rcov::RcovTask.new do |t|
  pattern = 'test/**/*.rb'
  
  t.test_files = FileList[pattern]
  t.verbose = true
  t.libs = %w[lib test .]
  t.rcov_opts << "--no-color"
  t.rcov_opts << "--save coverage.info"
  t.rcov_opts << "-x ^/"
  t.rcov_opts << "-x tmp/isolate"
  t.rcov_opts << "--sort coverage --sort-reverse"
end

# task :rcov do
#   test_names = Dir.glob('test/*_test.rb').map{|fname| "'#{fname}'"}.join(' ')
#   sh "ruby -Ilib:test:. -S rcov --text-report -w -I../../sexp_processor/dev/lib:lib:bin:test:. --no-color --save coverage.info -x ^/ -x tmp/isolate --sort coverage --sort-reverse -o 'coverage' #{test_names} GAH.rb"
# end
