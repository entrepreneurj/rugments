module Rugments
  module Lexers
    class PlainText < Lexer
      title 'Plain Text'
      desc "A boring lexer that doesn't highlight anything"

      tag 'plaintext'
      aliases 'text'
      filenames '*.txt'
      mimetypes 'text/plain'

      default_options token: 'Text'

      def token
        @token ||= Token[option :token]
      end

      def stream_tokens(string, &_b)
        yield token, string
      end
    end
  end
end
