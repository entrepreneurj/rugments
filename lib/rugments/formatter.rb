module Rugments
  # A Formatter takes a token stream and formats it for human viewing.
  class Formatter
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
  end
end

require_relative 'formatters/html'
require_relative 'formatters/terminal256'
require_relative 'formatters/null'
