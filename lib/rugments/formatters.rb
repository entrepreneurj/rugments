module Rugments
  class Formatter
    REGISTRY = {}

    def self.tag(tag = nil)
      return @tag unless tag
      REGISTRY[tag.to_sym] = self

      @tag = tag
    end

    def self.find(tag)
      REGISTRY[tag.to_sym]
    end
  end
end

lib_path = File.expand_path(File.dirname(__FILE__))
Dir.glob(File.join(lib_path, 'formatters/*.rb')) { |f| require_relative f }
