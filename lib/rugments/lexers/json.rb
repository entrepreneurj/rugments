module Rugments
  module Lexers
    class JSON < RegexLexer
      desc 'JavaScript Object Notation (json.org)'
      tag 'json'
      filenames '*.json'
      mimetypes 'application/json'

      # TODO: is this too much of a performance hit?  JSON is quite simple,
      # so I'd think this wouldn't be too bad, but for large documents this
      # could mean doing two full lexes.
      def self.analyze_text(text)
        return 0.8 if text =~ /\A\s*{/m && text.lexes_cleanly?(self)
        end

      state :root do
        mixin :whitespace
        # special case for empty objects
        rule /(\{)(\s*)(\})/m do
          groups Punctuation, Text::Whitespace, Punctuation
        end
        rule /(?:true|false|null)\b/, Keyword::Constant
        rule /{/,  Punctuation, :object_key
        rule /\[/, Punctuation, :array
        rule /-?(?:0|[1-9]\d*)\.\d+(?:e[+-]\d+)?/i, Num::Float
        rule /-?(?:0|[1-9]\d*)(?:e[+-]\d+)?/i, Num::Integer
        mixin :has_string
      end

      state :whitespace do
        rule /\s+/m, Text::Whitespace
      end

      state :has_string do
        rule /"(\\.|[^"])*"/, Str::Double
      end

      state :object_key do
        mixin :whitespace
        mixin :has_string
        rule /:/, Punctuation, :object_val
        rule /}/, Error, :pop!
      end

      state :object_val do
        rule /,/, Punctuation, :pop!
        rule(/}/) { token Punctuation; pop!(2) }
        mixin :root
      end

      state :array do
        rule /\]/, Punctuation, :pop!
        rule /,/, Punctuation
        mixin :root
      end
    end
  end
end
