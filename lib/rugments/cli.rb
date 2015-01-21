require 'thor'
require 'thor/version'
require 'rugments'

module Rugments
  class Cli < Thor
    desc 'lexers', 'Print a list of all lexers'
    def lexers
      lexers = Rugments::Lexer.all
      lexers.each { |lexer| puts lexer.title }
    end

    desc 'version', 'Print rugments version string'
    option :verbose, type: :boolean, aliases: '-v',
                     desc: "Print thor's and ruby's version as well"
    def version
      puts "rugments #{Rugments::VERSION}"
      puts "thor #{Thor::VERSION}" if options[:verbose]
      puts "ruby #{RUBY_VERSION}" if options[:verbose]
    end
  end
end
