PKG_VERSION = '0.1.dev'

Gem::Specification.new do |s|
  # These dependencies appear in the Gemfile.
  s.add_development_dependency('rake', '~> 0.9.2')
  s.add_development_dependency('rantly', '~> 0.3.1')
  s.add_development_dependency('rspec', '~> 2.7.0')

  s.platform = Gem::Platform::RUBY
  s.summary = 'Huet-style zipper.'
  s.name = 'zipr'
  s.homepage = 'https://github.com/frankshearar/zipr/'
  s.email = 'frank@angband.za.org'
  s.license = 'MIT'
  s.authors = ['Frank Shearar']
  s.version = PKG_VERSION
  s.requirements << 'none'
  s.require_paths = ['lib']
  s.required_rubygems_version = Gem::Requirement.new('>= 1.3.6') if s.respond_to? :required_rubygems_version=
  # ls-files shows only those files under version control.
  s.files = `git ls-files lib`.split("\n")
  s.test_files = `git ls-files test`.split("\n")
  s.description = <<EOF
  Zipr provides a principled way of navigating through and mutating
  immutable data structures.
EOF
end
