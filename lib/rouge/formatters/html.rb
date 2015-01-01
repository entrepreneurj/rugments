require 'cgi'

module Rouge
  module Formatters
    class HTML < Formatter
      tag('html')

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
          format_untableized(tokens)
        else
          format_untableized(tokens)
        end
      end

      private

      def format_untableized(tokens)
        data = process_tokens(tokens)

        html = ''
        html << "<pre class=\"#{@css_class}\"><code>" unless @nowrap
        html << create_lines(data[:code])
        html << "</code></pre>\n" unless @nowrap
        html
      end

      def format_tableized(tokens)
        data = process_tokens(tokens)

        html = ''
        html << "<div class=\"#{@css_class}\">\n" unless @nowrap
        html << "<table><tbody>\n"
        html << "<td class=\"linenos\"><pre>"
        html << create_linenos(data[:numbers])
        html << "</pre></td>\n"
        html << "<td class=\"lines\"><pre><code>"
        html << create_lines(data[:code])
        html << "</code></pre></td>\n"
        html << "</tbody></table>\n"
        html << "</div>\n" unless @nowrap
      end

      def process_tokens(tokens)
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

        { numbers: numbers, code: formatted }
      end

      def create_linenos(numbers)
        if @anchorlinenos
          numbers.map! do |number|
            "<a href=\"#line-#{number}\">#{number}</a>"
          end
        end
        numbers.join("\n")
      end

      def create_lines(formatted)
        if @lineanchors
          lines = formatted.split("\n")
          lines = lines.each_with_index.map do |line, index|
            number = index + @start_line

            if @linenos == 'inline'
              "<a name=\"line-#{number}\"></a>" \
              "<span class=\"linenos\">#{number}</span>#{line}"
            else
              "<a name=\"line-#{number}\"></a>#{line}"
            end
          end
          lines.join("\n")
        else
          if @linenos == 'inline'
            lines = formatted.split("\n")
            lines = lines.each_with_index.map do |line, index|
              number = index + @start_line
              "<span class=\"linenos\">#{number}</span>#{line}"
            end
            lines.join("\n")
          else
            formatted
          end
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
