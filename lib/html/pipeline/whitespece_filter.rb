module HTML
  class Pipeline
    # HTML filter that transforms all linefeeds into the equivalent HTML tag.
    # Strings within <p>, <pre>, and <code> elements are ignored.
    class WhitespaceFilter < Filter
      # Public: Find multiple, consequtive linefeeds in text. See
      # NumericalWordFilter#numerical_word_formatting_filter.
      #
      #   WhitespaceFilter.paragraph_formatting_filter(text) do |match, content|
      #     '</p><p>'
      #   end
      #
      # text - String text to search.
      #
      # Yields the String match, the String linefeeds. The yield's return
      # replaces the match in the original text.
      #
      # Returns a String replaced with the return of the block.
      def self.multiple_linefeeds_in(text)
        text.gsub ParagraphPattern do |match|
          content = $1
          yield match, content
        end
      end

      # Public: Find all linefeeds in text. See
      # NumericalWordFilter#numerical_word_formatting_filter.
      #
      #   WhitespaceFilter.linebreak_formatting_filter(text) do |match, content|
      #     "#{content}<br>"
      #   end
      #
      # text - String text to search.
      #
      # Yields the String match, the String linefeed. The yield's return
      # replaces the match in the original text.
      #
      # Returns a String replaced with the return of the block.
      def self.all_linefeeds_in(text)
        text.gsub LinebreakPattern do |match|
          content = $1
          yield match, content
        end
      end

      LinebreakPattern = /
        (.*)\n # Any character followed by a linefeed
      /ix

      ParagraphPattern = /
        (<br>){2,} # Any multiple, consequtive <BR> tags
      /ix

      # Don't convert consecutive BR tags into P tags in text nodes that are children of these elements
      IGNORE_PARAGRAPHS = %w{q}.to_set

      # Don't look for linefeeds in text nodes that are children of these elements
      IGNORE_PARENTS = %w(p pre code).to_set

      def call
        # https://github.com/sparklemotion/nokogiri/issues/1233#issuecomment-71462081
        doc.xpath(".//text()").each do |node|
          content = node.to_html
          next if content !~ %r{\n+}
          next if has_ancestor?(node, IGNORE_PARENTS)

          html = if has_ancestor?(node, IGNORE_PARAGRAPHS)
            linebreak_formatting_filter(content)
          else
            whitespace_formatting_filter(content)
          end

          next if html == content
          node.replace(html)
        end
        doc
      end

      # Replaces all linefeeds into the equivalent HTML tag
      #
      # text      - String text to replace linefeeds in.
      #
      # Returns a string with linefeeds replaced with HTML tags. Single
      # linefeeds are converted into <BR>s and multiple consequtive linefeeds
      # are converted into <P>s
      def whitespace_formatting_filter( text )
        html = linebreak_formatting_filter( text )

        paragraph_formatting_filter( html )
      end

      def linebreak_formatting_filter( text )
        self.class.all_linefeeds_in(text) do |match, content|
          "#{content}<br>"
        end
      end

      # Transforms all multiple linefeeds into a P tag
      def paragraph_formatting_filter( text )
        text = self.class.multiple_linefeeds_in(text) do |match, content|
          '</p><p>'
        end

        wrap_result text
      end

      # Wraps the formatted text in containing P tags if any were added
      def wrap_result( text )
        if text =~ %r{/p>}
          "<p>#{text}</p>"
        else
          text
        end
      end
    end
  end
end
