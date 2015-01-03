require_relative 'rugments/version'
require_relative 'rugments/utils'
require_relative 'rugments/tokens'
require_relative 'rugments/lexers'
require_relative 'rugments/formatters'
require_relative 'rugments/themes'

module Rugments
  module_function

  # TODO: Make this basic method more powerful!
  def highlight(text, lexer, formatter)
    lexer = Lexer.find(lexer) unless lexer.respond_to?(:lex)
    fail "unknown lexer #{lexer}" unless lexer

    formatter = Formatter.find(formatter) unless formatter.respond_to?(:render)
    fail "unknown formatter #{formatter}" unless formatter

    formatter.render(lexer.lex(text))
  end
end
