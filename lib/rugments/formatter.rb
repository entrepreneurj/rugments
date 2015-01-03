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
  end
end

lib_path = File.expand_path(File.dirname(__FILE__))
Dir.glob(File.join(lib_path, 'formatters/*.rb')) { |f| require_relative f }
