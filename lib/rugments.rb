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

  # TODO: Make this basic method more powerful!
  def highlight(text, lexer, formatter)
    lexer = Lexer.find(lexer) unless lexer.respond_to?(:lex)
    fail "unknown lexer #{lexer}" unless lexer

    formatter = Formatter.find(formatter) unless formatter.respond_to?(:render)
    fail "unknown formatter #{formatter}" unless formatter

    formatter.render(lexer.lex(text))
  end
end
