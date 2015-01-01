require_relative 'rugments/version'
require_relative 'rugments/util'
require_relative 'rugments/text_analyzer'
require_relative 'rugments/token'
require_relative 'rugments/lexer'
require_relative 'rugments/regex_lexer'
require_relative 'rugments/template_lexer'
require_relative 'rugments/formatter'
require_relative 'rugments/theme'

module Rugments
  module_function

  # Highlight some text with a given lexer and formatter.
  #
  # @example
  #   Rouge.highlight('@foo = 1', 'ruby', 'html')
  #   Rouge.highlight('var foo = 1;', 'js', 'terminal256')
  #
  #   # streaming - chunks become available as they are lexed
  #   Rouge.highlight(large_string, 'ruby', 'html') do |chunk|
  #     $stdout.print chunk
  #   end
  def highlight(text, lexer, formatter, &b)
    lexer = Lexer.find(lexer) unless lexer.respond_to?(:lex)
    fail "unknown lexer #{lexer}" unless lexer

    formatter = Formatter.find(formatter) unless formatter.respond_to?(:format)
    fail "unknown formatter #{formatter}" unless formatter

    formatter.format(lexer.lex(text), &b)
  end
end
