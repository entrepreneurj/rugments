require 'rake'
require_relative 'lib/rugments/version'

Gem::Specification.new do |s|
  s.name = 'rugments'
  s.version = Rugments::VERSION
  s.authors = ['Jeanine Adkisson', 'Stefan Tatschner']
  s.email = ['jneen@jneen.net', 'stefan@sevenbyte.org']
  s.summary = 'A pure-ruby colorizer based on pygments'
  s.description = 'Rugments aims to a be a simple,' \
                  'easy-to-extend drop-in replacement for pygments.'
  s.homepage = 'https://github.com/rumpelsepp/rugments'
  s.files = FileList[
    'README.md',
    'LICENSE',
    'bin/*',
    'lib/**/*.rb',
    'lib/**/*.yml',
  ].to_a
  s.executables = %w(rugmentize)
  s.license = 'MIT'
end
