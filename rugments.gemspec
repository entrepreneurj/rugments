require 'rake'
require_relative 'lib/rugments/version'

Gem::Specification.new do |s|
  s.name = 'rugments'
  s.version = Rugments::VERSION
  s.authors = %w(Jeanine Adkisson Stefan Tatschner)
  s.email = 'stefan@sevenbyte.org'
  s.summary = 'A highlighter in Ruby which is compatible with pygments'
  s.description = 'Rugments aims to a be a simple, easy-to-extend ' \
                  'drop-in replacement for pygments.'
  s.homepage = 'https://github.com/rumpelsepp/rugments'
  s.files = FileList[
    'LICENSE',
    'bin/*',
    'lib/**/*.rb',
    'lib/**/*.yml'
  ].to_a
  s.executables = %w(rugmentize)
  s.license = 'MIT'
  s.add_runtime_dependency('thor')
end
