module Rugments
  class TextAnalyzer < String
    # Find a shebang. Returns nil if no shebang is present.
    def shebang
      return @shebang if instance_variable_defined?(:@shebang)

      if self =~ /\A\s*#!(.*)$/
        @shebang = Regexp.last_match[1]
      end
    end

    # Check if the given shebang is present.
    #
    # This normalizes things so that `text.shebang?('bash')` will detect
    # `#!/bash`, '#!/bin/bash', '#!/usr/bin/env bash', and '#!/bin/bash -x'
    def shebang?(match)
      shebang =~ /\b#{match}(\s|$)/ ? true : false
    end

    # Return the contents of the doctype tag if present, nil otherwise.
    def doctype
      return @doctype if instance_variable_defined?(:@doctype)

      # possible <?xml...?> tag
      if self =~ /\A\s*(?:<\?.*?\?>\s*)?<!DOCTYPE\s+(.+?)>/
        @doctype = Regexp.last_match[1]
      end
    end

    # Check if the doctype matches a given regexp or string
    def doctype?(type = //)
      doctype =~ type ? true : false
    end

    # Return true if the result of lexing with the given lexer contains no
    # error tokens.
    def lexes_cleanly?(lexer)
      lexer.lex(self) do |(tok, _)|
        return false if tok.name == 'Error'
      end

      true
    end
  end
end
