require 'cgi'

module Rugments
  module Formatters
    class HTML < Formatter
      tag 'html'

      def initialize(
          nowrap: false,
          cssclass: 'highlight',
          linenos: nil,
          linenostart: 1,
          lineanchors: false,
          lineanchorsid: 'L',
          anchorlinenos: false,
          inline_theme: nil
        )
        @nowrap = nowrap
        @cssclass = cssclass
        @linenos = linenos
        @linenostart = linenostart
        @lineanchors = lineanchors
        @lineanchorsid = lineanchorsid
        @anchorlinenos = anchorlinenos
        @inline_theme = inline_theme
      end

      def render(tokens)
        case @linenos
        when 'table'
          render_tableized(tokens)
        when 'inline'
          render_untableized(tokens)
        else
          render_untableized(tokens)
        end
      end

      private

      def render_untableized(tokens)
        data = process_tokens(tokens)

        html = []
        html << "<pre class=\"#{@cssclass}\"><code>" unless @nowrap
        html << wrap_lines(data[:code])
        html << "</code></pre>\n" unless @nowrap
        html.join("\n")
      end

      def render_tableized(tokens)
        data = process_tokens(tokens)

        html = []
        html << "<div class=\"#{@cssclass}\">" unless @nowrap
        html << '<table><tbody>'
        html << "<td class=\"linenos\"><pre>"
        html << wrap_linenos(data[:numbers])
        html << '</pre></td>'
        html << "<td class=\"lines\"><pre><code>"
        html << wrap_lines(data[:code])
        html << '</code></pre></td>'
        html << '</tbody></table>'
        html << '</div>' unless @nowrap
        html.join("\n")
      end

      def process_tokens(tokens)
        num_lines = 0
        last_val = ''
        rendered = ''

        tokens.each do |tok, val|
          last_val = val
          num_lines += val.scan(/\n/).size
          rendered << span(tok, val)
        end

        numbers = (@linenostart..num_lines + @linenostart - 1).to_a

        # Add an extra line for non-newline-terminated strings.
        unless last_val[-1] == "\n"
          num_lines += 1
          rendered << span(Token::Tokens::Text::Whitespace, "\n")
        end

        { numbers: numbers, code: rendered }
      end

      def wrap_linenos(numbers)
        if @anchorlinenos
          numbers.map! do |number|
            "<a href=\"##{@lineanchorsid}#{number}\">#{number}</a>"
          end
        end
        numbers.join("\n")
      end

      def wrap_lines(rendered)
        if @lineanchors
          lines = rendered.split("\n")
          lines = lines.each_with_index.map do |line, index|
            number = index + @linenostart

            if @linenos == 'inline'
              "<a name=\"L#{number}\"></a>" \
              "<span class=\"linenos\">#{number}</span>" \
              "<span id=\"#{@lineanchorsid}#{number}\" class=\"line\">#{line}" \
              '</span>'
            else
              "<span id=\"#{@lineanchorsid}#{number}\" class=\"line\">#{line}" \
              '</span>'
            end
          end
          lines.join("\n")
        else
          if @linenos == 'inline'
            lines = rendered.split("\n")
            lines = lines.each_with_index.map do |line, index|
              number = index + @linenostart
              "<span class=\"linenos\">#{number}</span>#{line}"
            end
            lines.join("\n")
          else
            rendered
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
