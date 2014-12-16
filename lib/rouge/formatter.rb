module Rouge
  # A Formatter takes a token stream and formats it for human viewing.
  class Formatter
    alias_method :render, :format

    REGISTRY = {}

    # Specify or get the unique tag for this formatter.  This is used
    # for specifying a formatter in `rougify`.
    def self.tag(tag = nil)
      return @tag unless tag
      REGISTRY[tag] = self

      @tag = tag
    end

    # Find a formatter class given a unique tag.
    def self.find(tag)
      REGISTRY[tag]
    end

    # Format a token stream.  Delegates to {#format}.
    def self.format(tokens, opts = {}, &b)
      new(opts).format(tokens, &b)
    end

    # Format a token stream.
    def format(tokens, &b)
      return stream(tokens, &b) if block_given?

      out = ''
      stream(tokens) { |piece| out << piece }

      out
    end

    # @abstract
    # yield strings that, when concatenated, form the formatted output
    def stream(_tokens, &_b)
      fail 'abstract'
    end
  end
end


require_relative 'formatters/html'
require_relative 'formatters/terminal256'
require_relative 'formatters/null'
