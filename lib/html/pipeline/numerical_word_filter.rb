module HTML
  class Pipeline
    # HTML filter that wraps any word with a numerical word in it with <strong>.
    # Strings within <pre> and <code> elements are ignored. Certain
    # non-alphanumeric characters are included in the match including $, :, -, +,
    # (, ), [, ], etc. This ensures that the entire "word" is wrapped.
    #
    # Context options:
    #   :numerical_word_tag_buider -  Proc that accepts a numerical_word and returns an HTML tag string.
    #
    class NumericalWordFilter < Filter
      # Public: Find numerical_word-words in text.  See
      # NumericalWordFilter#numerical_word_formatting_filter.
      #
      #   NumericalWordFilter.numerical_words_in(text) do |match, numerical_word|
      #     "<strong class=...>#{numerical_word}</strong>"
      #   end
      #
      # text - String text to search.
      #
      # Yields the String match, the String numerical_word-word. The yield's return
      # replaces the match in the original text.
      #
      # Returns a String replaced with the return of the block.
      def self.numerical_words_in(text)
        return if text.nil?

        text.gsub FILTER_REGEX do |match|
          numerical_word = Regexp.last_match(1)

          yield match, numerical_word
        end
      end

      FILTER_REGEX = %r{
        (?:^|\W)                   # beginning of string or non-word char
        ((?>
          \w*                      # Any word prefix
          (
            (?>[^a-z|\s|,|\.])*    # Any non-word prefix (+ - $ etc.)
            \d                     # Any digit
            (?>[^a-z|\s|,|\.|/])*  # Any non-word suffix (: , . etc.)
          )+
          (?>[,\.]\d+)*            # trailing dots, commas, and hyphens
        \w*))                      # Any word suffix
      }ix.freeze

      # Don't look for numerical_word-word in text nodes that are children of these elements
      IGNORE_PARENTS = %w[pre code style script].to_set

      def call
        result[:numerical_words] ||= []

        doc.search('.//text()').each do |node|
          content = node.to_html
          next unless content =~ /\d+/
          next if has_ancestor?(node, IGNORE_PARENTS)

          html = numerical_word_formatting_filter(content)
          next if html == content

          node.replace(html)
        end
        doc
      end

      # Returns a proc that accept a numerical_word and returns an HTML string.
      def numerical_word_tag_builder
        context[:numerical_word_tag_builder] || ->(numerical_word) { %(<span class="numerical-word-#{numerical_word}">#{numerical_word}</span>) }
      end

      # Replace numerical_word words in text with specific markup indicating a
      # numerical_word-word..
      #
      # text      - String text to replace numerical_word-words in.
      #
      # Returns a string with numerical_word words replaced with HTML. All HTML will
      # have a CSS class name attached for styling.
      def numerical_word_formatting_filter(text)
        self.class.numerical_words_in(text) do |match, numerical_word|
          result[:numerical_words] |= [numerical_word]
          link = numerical_word_tag_builder.call(numerical_word)

          link ? match.sub(numerical_word, link) : match
        end
      end
    end
  end
end
