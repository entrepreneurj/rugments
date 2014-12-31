require 'cgi'

module Rouge
  module Formatters
    # Transforms a token stream into HTML output.
    class HTML < Formatter
      tag('html')

      # @option opts [String] :css_class ('highlight')
      # @option opts [true/false] :line_numbers (false)
      # @option opts [Rouge::CSSTheme] :inline_theme (nil)
      # @option opts [true/false] :wrap (true)
      #
      # Initialize with options.
      #
      # If `:inline_theme` is given, then instead of rendering the
      # tokens as <span> tags with CSS classes, the styles according to
      # the given theme will be inlined in "style" attributes.  This is
      # useful for formats in which stylesheets are not available.
      #
      # Content will be wrapped in a tag (`div` if tableized, `pre` if
      # not) with the given `:css_class` unless `:wrap` is set to `false`.
      def initialize(
          css_class: 'highlight',
          linenos: nil,
          lineanchors: false,
          anchorlinenos: false,
          start_line: 1,
          inline_theme: nil,
          nowrap: false
        )
        @css_class = css_class
        @linenos = linenos
        @lineanchors = lineanchors
        @anchorlinenos = anchorlinenos
        @start_line = start_line
        @inline_theme = inline_theme
        @nowrap = nowrap
      end

      def format(tokens)
        case
        when @linenos == 'table'
          format_tableized(tokens)
        when @linenos == 'inline'
        else
          format_untableized(tokens)
        end
      end

      private

      def format_untableized(tokens)
        html = ''
        html << "<pre class=\"#{@css_class}\"><code>" unless @nowrap
        tokens.each { |tok, val| html << span(tok, val) }
        html << "</code></pre>\n" unless @nowrap
        html
      end

      def format_tableized(tokens)
        num_lines = 0
        last_val = ''
        formatted = ''

        tokens.each do |tok, val|
          last_val = val
          num_lines += val.scan(/\n/).size
          formatted << span(tok, val)
        end

        numbers = (@start_line..num_lines + @start_line - 1).to_a

        # Add an extra line for non-newline-terminated strings.
        unless last_val[-1] == "\n"
          num_lines += 1
          formatted << span(Token::Tokens::Text::Whitespace, "\n")
        end

        html = "<div class=\"#{@css_class}\">\n" unless @nowrap
        html << "<table><tbody>\n"
        html << "<td class=\"linenos\"><pre>"
        html << create_linenos(numbers)
        html << "</pre></td>\n"
        html << "<td class=\"lines\"><pre><code>"
        html << create_lines(formatted)
        html << "</code></pre></td>\n"
        html << "</tbody></table>\n"
        html << "</div>\n" unless @nowrap
      end

      def create_linenos(numbers)
        if @anchorlinenos
          numbers.map! do |number|
            number = "<a href=\"#line-#{number}\">#{number}</a>"
          end
        end
        numbers.join("\n")
      end

      def create_lines(formatted)
        if @lineanchors
          lines = formatted.split("\n")
          lines = lines.each_with_index.map do |line, index|
            number = index + @start_line
            line = "<a name=\"line-#{number}\"></a>#{line}"
          end
          lines.join("\n")
        else
          formatted
        end
      end

      def span(tok, val)
        # http://stackoverflow.com/a/1600584/2587286
        val = CGI.escapeHTML(val)

        if tok.shortname.empty?
          val
        else
          if @inline_theme
            theme = Theme.find(@inline_theme).new
            rules = theme.style_for(tok).rendered_rules
            "<span style=\"#{rules.to_a.join(';')}\">#{val}</span>"
          else
            "<span class=\"#{tok.shortname}\">#{val}</span>"
          end
        end
      end
    end
  end
end
