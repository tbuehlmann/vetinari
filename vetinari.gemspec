# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'vetinari/version'

Gem::Specification.new do |spec|
  spec.name          = 'vetinari'
  spec.version       = Vetinari::VERSION
  spec.authors       = ['Tobias Bühlmann']
  spec.email         = ['tobias.buehlmann@gmx.de']
  spec.description   = <<-EOS
    Vetinari is a multithreaded IRC Bot Framework using the Celluloid::IO
    library.
  EOS
  spec.summary       = 'Multithreaded IRC Bot Framework.'
  spec.homepage      = 'https://github.com/tbuehlmann/vetinari'
  spec.license       = 'MIT'

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.required_ruby_version = '>= 1.9.2'

  spec.add_dependency 'celluloid-io', '~> 0.13'

  spec.add_development_dependency 'bundler', '~> 1.3'
  spec.add_development_dependency 'pry', '~> 0.9'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'rspec', '~> 2.13'
end
