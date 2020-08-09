module HTML
  class Pipeline
    # HTML filter that replaces #hashtag strings with links. Hashtags within <pre>,
    # <code>, and <a> elements are ignored. Hashtags that do not reference a
    # predefined that hashtag are ignored.
    #
    # Context options:
    #   :hashtag_validator - Proc that accepts a hashtag and returns true/false.
    #   :hashtag_tag_buider -  Proc that accepts a hashtag and returns an HTML tag string.
    #
    class HashtagFilter < Filter
      # Public: Find hashtag #hashtags in text.  See
      # HashtagFilter#hashtag_link_filter.
      #
      #   HashtagFilter.hashtags_in(text) do |match, login, is_valid|
      #     "<a href=...>#{hashtag}</a>"
      #   end
      #
      # text - String text to search.
      #
      # Yields the String match, the String hashtag name, and a
      # Hashtag instance if the name matches a predefined record in
      # the database.
      #
      # The yield's return replaces the match in the original text.
      #
      # Returns a String replaced with the return of the block.
      def self.hashtags_in(text)
        return if text.nil?

        text.gsub FILTER_REGEX do |match|
          name = Regexp.last_match(1)

          yield match, name
        end
      end

      # Pattern used to extract #hashtags from text.
      FILTER_REGEX = %r{
        (?:^|\W)                   # beginning of string or non-word char
        \#((?>[a-z][a-z-]*))       # #hashtag containing only non-numbers
        (?!/)                      # without a trailing slash
        (?=
          \.+[ \t\W]|              # dots followed by space or non-word character
          \.+$|                    # dots at end of line
          [^0-9a-zA-Z_.]|          # non-word character except dot
          $                        # end of line
        )
      }ix.freeze

      # Don't look for hashtags in text nodes that are children of these elements
      IGNORE_PARENTS = %w[pre code a style script].to_set

      def call
        result[:hashtags] ||= []

        doc.search('.//text()').each do |node|
          content = node.to_html
          next unless content.include?('#')
          next if has_ancestor?(node, IGNORE_PARENTS)

          html = hashtag_link_filter(content)
          next if html == content

          node.replace(html)
        end
        doc
      end

      # Returns a proc that accepts a hashtag and returns true/false.
      def hashtag_validator
        context[:hashtag_validator] || ->(_hashtag) { true }
      end

      # Returns a proc that accept a hashtag and returns an HTML string.
      def hashtag_tag_buider
        context[:hashtag_tag_builder] || ->(hashtag) { %(<span class="hashtag-#{hashtag}">#{hashtag}</span>) }
      end

      # Replace #hashtags in text with specific markup indicating a hashtag.
      #
      # text      - String text to replace #hashtags in.
      #
      # Returns a string with #hashtags replaced with HTML. All HTML will have a
      # CSS class name attached for styling.
      def hashtag_link_filter(text)
        self.class.hashtags_in(text) do |match, hashtag|
          result[:hashtags] |= [hashtag]

          link = if hashtag_validator.call(hashtag)
                   hashtag_tag_buider.call(hashtag)
                 else
                   "##{hashtag}"
                 end

          link ? match.sub("##{hashtag}", link) : match
        end
      end
    end
  end
end
