module Rugments
  module Theme
    class ThemeBase
      include Tokens

      class << self
        def tag(val = nil)
          if val.nil?
            @tag
          else
            @tag ||= val
          end
        end

        def background_color(val = nil)
          if val.nil?
            @background_color
          else
            @background_color ||= val
          end
        end

        def highlight_color(val = nil)
          if val.nil?
            @highlight_color
          else
            @highlight_color ||= val
          end
        end

        def styles(val = nil)
          if val.nil?
            @styles
          else
            @styles ||= val
          end
        end

        # TODO: Remember this one!
        # http://javieracero.com/blog/the-key-to-ruby-hashes-is-eql-hash
        def style_for_token(token)
          styles[token]
        end
      end
    end

    class BW < ThemeBase
      tag 'bw'
      background_color '#ffffff'

      styles Comment              => 'italic',
             Comment::Preproc     => 'noitalic',

             Keyword              => 'bold',
             Keyword::Pseudo      => 'nobold',
             Keyword::Type        => 'nobold',

             Operator::Word       => 'bold',

             Name::Class          => 'bold',
             Name::Namespace      => 'bold',
             Name::Exception      => 'bold',
             Name::Entity         => 'bold',
             Name::Tag            => 'bold',

             String               => 'italic',
             # String::Interpol   => 'bold',
             # String::Escape     => 'bold',

             Generic::Heading     => 'bold',
             Generic::Subheading  => 'bold',
             Generic::Emph        => 'italic',
             Generic::Strong      => 'bold',
             Generic::Prompt      => 'bold',

             Error                => 'border:#FF0000'

      p style_for_token(Error)
    end
  end
end

# lib_path = File.expand_path(File.dirname(__FILE__))
# Dir.glob(File.join(lib_path, 'themes/*.rb')) { |f| require_relative f }
