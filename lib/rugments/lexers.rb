require 'strscan'
require 'cgi'
require 'set'

module Rugments
  class Lexer
    include Tokens

    class << self
      # Sets/Gets the class instance variable @title. You are
      # supposed to set this variable in a lexer definition.
      #
      # title should be a human readable lexer name, e.g. "Ruby".
      def title(val = nil)
        if val.nil?
          @title
        else
          @title ||= val
        end
      end

      # Sets/Gets the class instance variable @desc. You are
      # supposed to set this variable in a lexer definition.
      #
      # It contains a short description of the lexer, such as
      # "The Ruby programming language (ruby-lang.org)".
      def desc(val = nil)
        if val.nil?
          @desc
        else
          @desc ||= val
        end
      end

      # Sets/Gets the class instance variable @tag. You are
      # supposed to set this variable in a lexer definition.
      #
      # tag must be a unique identifier for the lexer. It is
      # used internally as the "key" of LEXERS_CACHE.
      def tag(val = nil)
        if val.nil?
          @tag
        else
          @tag ||= val.to_sym
        end
      end

      # Sets/Gets the class instance variable @aliases. You are
      # supposed to set this variable in a lexer definition.
      #
      # The lexer could be found by the tag or the aliases.
      def aliases(*vals)
        if vals.empty?
          @aliases
        else
          vals.map!(&:to_s)
          @aliases ||= []
          @aliases += vals
        end
      end

      # Sets/Gets the class instance variable @filenames. You are
      # supposed to set this variable in a lexer definition.
      #
      # This variable maps the lexer to filename patterns.
      def filenames(*vals)
        if vals.empty?
          @filenames
        else
          vals.map!(&:to_s)
          @filenames ||= []
          @filenames += vals
        end
      end

      # Sets/Gets the class instance variable @mimetypes. You are
      # supposed to set this variable in a lexer definition.
      #
      # This variable maps the lexer to mimetypes.
      def mimetypes(*vals)
        if vals.empty?
          @mimetypes
        else
          vals.map!(&:to_s)
          @mimetypes ||= []
          @mimetypes += vals
        end
      end

      def default_options(opts = {})
        @default_options ||= {}
        @default_options.merge!(opts)
        @default_options
      end

      def assert_utf8!(str)
        return if %w(US-ASCII UTF-8 ASCII-8BIT).include?(str.encoding.name)
        fail IOError, 'Bad encoding! Please convert your string to UTF-8.'
      end

      # Returns all lexer classes known by rugments. It reads the
      # Rugments::LEXERS_CACHE variable and loads the convenient
      # files.
      def all
        lexers = []

        lexers = LEXERS_CACHE.keys.map do |tag|
          require_relative LEXERS_CACHE[tag][:source_file]
          Object.const_get(LEXERS_CACHE[tag][:class_name])
        end

        lexers
      end

      # Returns a lexer class. You'll have to provide the tag
      # or an alias which are defined in the lexer class.
      def find_by_name(tag)
        tag.downcase!
        tag = tag.to_sym

        if LEXERS_CACHE.key?(tag)
          require_relative LEXERS_CACHE[tag][:source_file]
          Object.const_get(LEXERS_CACHE[tag][:class_name])
        else
          lexer = LEXERS_CACHE.select do |k, hash|
            hash[:aliases].include?(tag.to_s)
          end

          # LEXERS_CACHE.select returns a hash of lexer classes:
          #
          # { matlab: {
          #     class_name: 'Rugments::Lexers::Matlab',
          #     source_file: 'lexers/matlab.rb',
          #     aliases: ['m'],
          #     filenames: ['*.m'],
          #     mimetypes: ['text/x-matlab', 'application/x-matlab']
          #   }
          # }
          #
          # We just pick the values of it and take the first one.
          lexer = lexer.values.first

          require_relative lexer[:source_file]
          Object.const_get(lexer[:class_name])
        end
      end

      def lex(raw, opts = {})
        new(opts).lex(raw)
      end

      def guess(mimetype: nil, filename: nil, source: nil)
        lexers = all
        total_size = lexers.size

        lexers = filter_by_mimetype(lexers, mimetype) if mimetype
        return lexers[0] if lexers.size == 1

        lexers = filter_by_filename(lexers, filename) if filename
        return lexers[0] if lexers.size == 1

        if source
          # If we're filtering against *all* lexers, we only use confident
          # return values from analyze_text. But if we've filtered down already,
          # we can trust the analysis more.
          source_threshold = lexers.size < total_size ? 0 : 0.5
          return [best_by_source(lexers, source, source_threshold)].compact
        end

        return Lexers::PlainText if lexers.empty?
        return lexers[0]
      end

      def guess_for_mimetype(mimetype, source)
        guess(mimetype: mimetype, source: source)
      end

      def guess_for_filename(filename, source)
        guess(filename: filename, source: source)
      end

      private

      def filter_by_mimetype(lexers, mimetype)
        filtered = lexers.select { |lexer| lexer.mimetypes.include?(mimetype) }
        filtered.any? ? filtered : lexers
      end

      # returns a list of lexers that match the given filename with
      # equal specificity (i.e. number of wildcards in the pattern).
      # This helps disambiguate between, e.g. the Nginx lexer, which
      # matches `nginx.conf`, and the Conf lexer, which matches `*.conf`.
      # In this case, nginx will win because the pattern has no wildcards,
      # while `*.conf` has one.
      def filter_by_filename(lexers, filename)
        filename = File.basename(filename)

        out = []
        best_seen = nil
        lexers.each do |lexer|
          score = lexer.filenames.map do |pattern|
            if File.fnmatch?(pattern, filename, File::FNM_DOTMATCH)
              # specificity is better the fewer wildcards there are
              pattern.scan(/[*?\[]/).size
            end
          end.compact.min

          next unless score

          if best_seen.nil? || score < best_seen
            best_seen = score
            out = [lexer]
          elsif score == best_seen
            out << lexer
          end
        end

        out.any? ? out : lexers
      end

      def best_by_source(lexers, source, threshold = 0)
        source = case source
                 when String
                   source
                 when ->(s) { s.respond_to? :read }
                   source.read
                 else
                   fail 'invalid source'
                 end

        assert_utf8!(source)

        source = TextAnalyzer.new(source)

        best_result = threshold
        best_match = nil
        lexers.each do |lexer|
          result = lexer.analyze_text(source) || 0
          return lexer if result == 1

          if result > best_result
            best_match = lexer
            best_result = result
          end
        end

        best_match
      end
    end

    # instance methods

    # Create a new lexer with the given options.  Individual lexers may
    # specify extra options.  The only current globally accepted option
    # is `:debug`.
    #
    # @option opts :debug
    #   Prints debug information to stdout.  The particular info depends
    #   on the lexer in question.  In regex lexers, this will log the
    #   state stack at the beginning of each step, along with each regex
    #   tried and each stream consumed.  Try it, it's pretty useful.
    def initialize(opts = {})
      @options ||= {}
      @options.merge!(opts)

      self.class.default_options.merge(@options)

      # TODO: Reenable debug
      # @debug = option(:debug)
    end

    # Given a string, yield [token, chunk] pairs.  If no block is given,
    # an enumerator is returned.
    #
    # @option opts :continue
    #   Continue the lex from the previous state (i.e. don't call #reset!)
    def lex(string, opts = {})
      return enum_for(:lex, string) unless block_given?

      Lexer.assert_utf8!(string)

      reset! unless opts[:continue]

      # consolidate consecutive tokens of the same type
      last_token = nil
      last_val = nil
      stream_tokens(string) do |tok, val|
        next if val.empty?

        if tok == last_token
          last_val << val
          next
        end

        yield last_token, last_val if last_token
        last_token = tok
        last_val = val
      end

      yield last_token, last_val if last_token
    end

    # delegated to {Lexer.tag}
    def tag
      self.class.tag
    end
  end

  module Lexers
    def self.load_const(const_name, relpath)
      return if const_defined?(const_name)

      root = Pathname.new(__FILE__).dirname.join('lexers')
      load root.join(relpath)
    end
  end

  # A stateful lexer that uses sets of regular expressions to
  # tokenize a string. Most lexers are instances of RegexLexer.
  class RegexLexer < Lexer
    # A rule is a tuple of a regular expression to test, and a callback
    # to perform if the test succeeds.
    class Rule
      attr_reader :re
      attr_reader :callback
      attr_reader :beginning_of_line

      def initialize(re, callback)
        @re = re
        @callback = callback
        @beginning_of_line = re.source[0] == '^'
      end

      def inspect
        "#<Rule #{@re.inspect}>"
      end
    end

    # a State is a named set of rules that can be tested for or
    # mixed in.
    #
    # @see RegexLexer.state
    class State
      attr_reader :name, :rules

      def initialize(name, rules)
        @name = name
        @rules = rules
      end

      def inspect
        "#<#{self.class.name} #{@name.inspect}>"
      end
    end

    class StateDSL
      attr_reader :rules

      def initialize(name, &defn)
        @name = name
        @defn = defn
        @rules = []
      end

      def to_state(lexer_class)
        load!
        rules = @rules.map do |rule|
          rule.is_a?(String) ? lexer_class.get_state(rule) : rule
        end
        State.new(@name, rules)
      end

      def prepended(&defn)
        parent_defn = @defn
        StateDSL.new(@name) do
          instance_eval(&defn)
          instance_eval(&parent_defn)
        end
      end

      def appended(&defn)
        parent_defn = @defn
        StateDSL.new(@name) do
          instance_eval(&parent_defn)
          instance_eval(&defn)
        end
      end

      protected

      # Define a new rule for this state.
      #
      # @overload rule(re, token, next_state=nil)
      # @overload rule(re, &callback)
      #
      # @param [Regexp] re
      #   a regular expression for this rule to test.
      # @param [String] tok
      #   the token type to yield if `re` matches.
      # @param [#to_s] next_state
      #   (optional) a state to push onto the stack if `re` matches.
      #   If `next_state` is `:pop!`, the state stack will be popped
      #   instead.
      # @param [Proc] callback
      #   a block that will be evaluated in the context of the lexer
      #   if `re` matches.  This block has access to a number of lexer
      #   methods, including {RegexLexer#push}, {RegexLexer#pop!},
      #   {RegexLexer#token}, and {RegexLexer#delegate}.  The first
      #   argument can be used to access the match groups.
      def rule(re, tok = nil, next_state = nil, &callback)
        if tok.nil? && callback.nil?
          fail 'please pass `rule` a token to yield or a callback'
        end

        callback ||= case next_state
        when :pop!
          proc do |stream|
            puts "    yielding #{tok.qualname}, #{stream[0].inspect}" if @debug
            @output_stream.call(tok, stream[0])
            puts "    popping stack: #{1}" if @debug
            @stack.pop || fail('empty stack!')
          end
        when :push
          proc do |stream|
            puts "    yielding #{tok.qualname}, #{stream[0].inspect}" if @debug
            @output_stream.call(tok, stream[0])
            puts "    pushing #{@stack.last.name}" if @debug
            @stack.push(@stack.last)
          end
        when Symbol
          proc do |stream|
            puts "    yielding #{tok.qualname}, #{stream[0].inspect}" if @debug
            @output_stream.call(tok, stream[0])
            state = @states[next_state] || self.class.get_state(next_state)
            puts "    pushing #{state.name}" if @debug
            @stack.push(state)
          end
        when nil
          proc do |stream|
            puts "    yielding #{tok.qualname}, #{stream[0].inspect}" if @debug
            @output_stream.call(tok, stream[0])
          end
        else
          fail "invalid next state: #{next_state.inspect}"
        end

        rules << Rule.new(re, callback)
      end

      # Mix in the rules from another state into this state.  The rules
      # from the mixed-in state will be tried in order before moving on
      # to the rest of the rules in this state.
      def mixin(state)
        rules << state.to_s
      end

      private

      def load!
        return if @loaded
        @loaded = true
        instance_eval(&@defn)
      end
    end

    # The states hash for this lexer.
    # @see state
    def self.states
      @states ||= {}
    end

    def self.state_definitions
      @state_definitions ||= InheritableHash.new(superclass.state_definitions)
    end
    @state_definitions = {}

    def self.replace_state(name, new_defn)
      states[name] = nil
      state_definitions[name] = new_defn
    end

    # The routines to run at the beginning of a fresh lex.
    # @see start
    def self.start_procs
      @start_procs ||= InheritableList.new(superclass.start_procs)
    end
    @start_procs = []

    # Specify an action to be run every fresh lex.
    #
    # @example
    #   start { puts "I'm lexing a new string!" }
    def self.start(&b)
      start_procs << b
    end

    # Define a new state for this lexer with the given name.
    # The block will be evaluated in the context of a {StateDSL}.
    def self.state(name, &b)
      name = name.to_s
      state_definitions[name] = StateDSL.new(name, &b)
    end

    def self.prepend(name, &b)
      name = name.to_s
      dsl = state_definitions[name] or fail "no such state #{name.inspect}"
      replace_state(name, dsl.prepended(&b))
    end

    def self.append(_state, &b)
      name = name.to_s
      dsl = state_definitions[name] or fail "no such state #{name.inspect}"
      replace_state(name, dsl.appended(&b))
    end

    # @private
    def self.get_state(name)
      return name if name.is_a? State

      states[name.to_sym] ||= begin
        defn = state_definitions[name.to_s] or fail "unknown state: #{name.inspect}"
        defn.to_state(self)
      end
    end

    # @private
    def get_state(state_name)
      self.class.get_state(state_name)
    end

    # The state stack.  This is initially the single state `[:root]`.
    # It is an error for this stack to be empty.
    # @see #state
    def stack
      @stack ||= [get_state(:root)]
    end

    # The current state - i.e. one on top of the state stack.
    #
    # NB: if the state stack is empty, this will throw an error rather
    # than returning nil.
    def state
      stack.last || fail('empty stack!')
    end

    # reset this lexer to its initial state.  This runs all of the
    # start_procs.
    def reset!
      @stack = nil
      @current_stream = nil

      self.class.start_procs.each do |pr|
        instance_eval(&pr)
      end
    end

    # This implements the lexer protocol, by yielding [token, value] pairs.
    #
    # The process for lexing works as follows, until the stream is empty:
    #
    # 1. We look at the state on top of the stack (which by default is
    #    `[:root]`).
    # 2. Each rule in that state is tried until one is successful.  If one
    #    is found, that rule's callback is evaluated - which may yield
    #    tokens and manipulate the state stack.  Otherwise, one character
    #    is consumed with an `'Error'` token, and we continue at (1.)
    #
    # @see #step #step (where (2.) is implemented)
    def stream_tokens(str, &b)
      stream = StringScanner.new(str)

      @current_stream = stream
      @output_stream  = b
      @states         = self.class.states
      @null_steps     = 0

      until stream.eos?
        if @debug
          puts "lexer: #{self.class.tag}"
          puts "stack: #{stack.map(&:name).inspect}"
          puts "stream: #{stream.peek(20).inspect}"
        end

        success = step(state, stream)

        unless success
          puts '    no match, yielding Error' if @debug
          b.call(Token::Tokens::Error, stream.getch)
        end
      end
    end

    # The number of successive scans permitted without consuming
    # the input stream.  If this is exceeded, the match fails.
    MAX_NULL_SCANS = 5

    # Runs one step of the lex.  Rules in the current state are tried
    # until one matches, at which point its callback is called.
    #
    # @return true if a rule was tried successfully
    # @return false otherwise.
    def step(state, stream)
      state.rules.each do |rule|
        if rule.is_a?(State)
          puts "  entering mixin #{rule.name}" if @debug
          return true if step(rule, stream)
          puts "  exiting  mixin #{rule.name}" if @debug
        else
          puts "  trying #{rule.inspect}" if @debug

          # XXX HACK XXX
          # StringScanner's implementation of ^ is b0rken.
          # see http://bugs.ruby-lang.org/issues/7092
          # TODO: this doesn't cover cases like /(a|^b)/, but it's
          # the most common, for now...
          next if rule.beginning_of_line && !stream.beginning_of_line?

          if size = stream.skip(rule.re)
            puts "    got #{stream[0].inspect}" if @debug

            instance_exec(stream, &rule.callback)

            if size.zero?
              @null_steps += 1
              if @null_steps > MAX_NULL_SCANS
                puts '    too many scans without consuming the string!' if @debug
                return false
              end
            else
              @null_steps = 0
            end

            return true
          end
        end
      end

      false
    end

    # Yield a token.
    #
    # @param tok
    #   the token type
    # @param val
    #   (optional) the string value to yield.  If absent, this defaults
    #   to the entire last match.
    def token(tok, val = @current_stream[0])
      yield_token(tok, val)
    end

    # Yield tokens corresponding to the matched groups of the current
    # match.
    def groups(*tokens)
      tokens.each_with_index do |tok, i|
        yield_token(tok, @current_stream[i + 1])
      end
    end

    # Delegate the lex to another lexer.  The #lex method will be called
    # with `:continue` set to true, so that #reset! will not be called.
    # In this way, a single lexer can be repeatedly delegated to while
    # maintaining its own internal state stack.
    #
    # @param [#lex] lexer
    #   The lexer or lexer class to delegate to
    # @param [String] text
    #   The text to delegate.  This defaults to the last matched string.
    def delegate(lexer, text = nil)
      puts "    delegating to #{lexer.inspect}" if @debug
      text ||= @current_stream[0]

      lexer.lex(text, continue: true) do |tok, val|
        puts "    delegated token: #{tok.inspect}, #{val.inspect}" if @debug
        yield_token(tok, val)
      end
    end

    def recurse(text = nil)
      delegate(self.class, text)
    end

    # Push a state onto the stack.  If no state name is given and you've
    # passed a block, a state will be dynamically created using the
    # {StateDSL}.
    def push(state_name = nil, &b)
      push_state = if state_name
                     get_state(state_name)
                   elsif block_given?
                     StateDSL.new(b.inspect, &b).to_state(self.class)
                   else
                     # use the top of the stack by default
                     state
                   end

      puts "    pushing #{push_state.name}" if @debug
      stack.push(push_state)
    end

    # Pop the state stack.  If a number is passed in, it will be popped
    # that number of times.
    def pop!(times = 1)
      fail 'empty stack!' if stack.empty?

      puts "    popping stack: #{times}" if @debug

      stack.pop(times)

      nil
    end

    # replace the head of the stack with the given state
    def goto(state_name)
      fail 'empty stack!' if stack.empty?

      puts "    going to state #{state_name} " if @debug
      stack[-1] = get_state(state_name)
    end

    # reset the stack back to `[:root]`.
    def reset_stack
      puts '    resetting stack' if @debug
      stack.clear
      stack.push get_state(:root)
    end

    # Check if `state_name` is in the state stack.
    def in_state?(state_name)
      state_name = state_name.to_s
      stack.any? do |state|
        state.name == state_name.to_s
      end
    end

    # Check if `state_name` is the state on top of the state stack.
    def state?(state_name)
      state_name.to_s == state.name
    end

    private

    def yield_token(tok, val)
      return if val.nil? || val.empty?
      puts "    yielding #{tok.qualname}, #{val.inspect}" if @debug
      @output_stream.yield(tok, val)
    end
  end

  # A TemplateLexer is one that accepts a :parent option, to specify
  # which language is being templated.  The lexer class can specify its
  # own default for the parent lexer, which is otherwise defaulted to
  # HTML.
  class TemplateLexer < RegexLexer
    # the parent lexer - the one being templated.
    def parent
      return @parent if instance_variable_defined? :@parent
      @parent = option(:parent) || 'html'
      if @parent.is_a? ::String
        lexer_class = Lexer.find(@parent)
        @parent = lexer_class.new(options)
      end
    end

    start { parent.reset! }
  end
end
