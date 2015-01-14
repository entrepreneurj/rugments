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
      return nil unless self =~ /\A\s*(?:<\?.*?\?>\s*)?<!DOCTYPE\s+(.+?)>/

      @doctype = Regexp.last_match[1]
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

  class InheritableHash < Hash
    alias_method :own_keys, :keys

    def initialize(parent = nil)
      @parent = parent
    end

    def [](k)
      sup = super
      return sup if own_keys.include?(k)

      sup || parent[k]
    end

    def parent
      @parent ||= {}
    end

    def include?(k)
      super || parent.include?(k)
    end

    def each
      keys.each do |k|
        yield k, self[k]
      end
    end

    def keys
      keys = own_keys.concat(parent.keys)
      keys.uniq!
      keys
    end
  end

  class InheritableList
    include Enumerable

    def initialize(parent = nil)
      @parent = parent
    end

    def parent
      @parent ||= []
    end

    def each(&b)
      return enum_for(:each) unless block_given?

      parent.each(&b)
      own_entries.each(&b)
    end

    def own_entries
      @own_entries ||= []
    end

    def push(o)
      own_entries << o
    end

    alias_method :<<, :push
  end

  # shared methods for some indentation-sensitive lexers
  module Indentation
    def reset!
      super
      @block_state = nil
      @block_indentation = nil
    end

    # push a state for the next indented block
    def starts_block(block_state)
      @block_state = block_state
      @block_indentation = @last_indentation || ''
      puts "    starts_block #{block_state.inspect}" if @debug
      puts "    block_indentation: #{@block_indentation.inspect}" if @debug
    end

    # handle a single indented line
    def indentation(indent_str)
      puts "    indentation #{indent_str.inspect}" if @debug
      puts "    block_indentation: #{@block_indentation.inspect}" if @debug
      @last_indentation = indent_str

      # if it's an indent and we know where to go next,
      # push that state.  otherwise, push content and
      # clear the block state.
      if @block_state &&
         indent_str.start_with?(@block_indentation) &&
         indent_str != @block_indentation

        push @block_state
      else
        @block_state = @block_indentation = nil
        push :content
      end
    end
  end
end
