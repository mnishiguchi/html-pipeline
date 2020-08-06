module HTML
  class Pipeline
    # HTML filter that replaces @user mentions with links. Mentions within <pre>,
    # <code>, and <a> elements are ignored. Mentions that reference users that do
    # not exist are ignored.
    #
    # Context options:
    #   :username_pattern - Used to provide a custom regular expression to identify usernames
    #   :mention_validator - Proc that accepts a mention and returns true/false.
    #   :mention_tag_buider -  Proc that accepts a mention and returns an HTML tag string.
    #   :attention_tag_buider - Proc that accepts attention and mention strings and returns an HTML tag string.
    #
    class MentionAttentionFilter < Filter
      # Public: Find Role @mentions in text.  See
      # MentionAttentionFilter#mention_tag_filter.
      #
      #   MentionAttentionFilter.mentioned_usernames_in(text) do |match, mention, role|
      #     "<a href=...>#{role.name}</a>"
      #   end
      #
      # text - String text to search.
      #
      # Yields the String match, a Mention instance, and a Role instance
      # if the match is a predefined role.
      # The yield's return replaces the match in the original text.
      #
      # Returns a String replaced with the return of the block.
      def self.mentioned_usernames_in(text, username_pattern = USERNAME_PATTERN)
        return if text.nil?

        index = -1
        text.gsub FILTER_REGEX[username_pattern] do |match|
          mention = Regexp.last_match(1)
          attention = Regexp.last_match(2)
          index += 1
          yield match, mention, attention, index
        end
      end

      # Hash that contains all of the mention patterns used by the pipeline
      FILTER_REGEX = Hash.new do |hash, key|
        hash[key] = %r{
          (?:^|\W)                      # beginning of string or non-word char
          @((?>#{key}))                 # @username
          !?((?>[a-z0-9][a-z0-9_\-]*))? # !attention_tag
          (?!/)                         # without a trailing slash
          (?=
            \.+[ \t\W]|                 # dots followed by space or non-word character
            \.+$|                       # dots at end of line
            [^0-9a-zA-Z_.]|             # non-word character except dot
            $                           # end of line
          )
        }ix
      end

      # Default pattern used to extract usernames from text. The value can be
      # overriden by providing the username_pattern variable in the context.
      USERNAME_PATTERN = /[a-z0-9][a-z0-9-]*/.freeze

      # Don't look for mentions in text nodes that are children of these elements
      IGNORE_PARENTS = %w[pre code a style script].to_set

      def call
        result[:mentions] ||= []
        result[:attentions] ||= []

        doc.search('.//text()').each do |node|
          content = node.to_html
          next unless content.include?('@')
          next if has_ancestor?(node, IGNORE_PARENTS)

          html = mention_tag_filter(content, username_pattern)
          next if html == content

          node.replace(html)
        end
        doc
      end

      def username_pattern
        context[:username_pattern] || USERNAME_PATTERN
      end

      # Returns a proc that accepts a mention and returns true/false.
      def mention_validator
        context[:mention_validator] || ->(_mention) { true }
      end

      # Returns a proc that accept a mention and returns an HTML string.
      def mention_tag_buider
        context[:mention_tag_builder] || ->(mention) { %(<span class="mention-#{mention}">#{mention}</span>) }
      end

      # Returns a proc that accept an attention and a mention and returns an HTML string.
      def attention_tag_buider
        context[:attention_tag_buider] || ->(attention, _mention) { %(<span class="attention-#{attention}">#{attention}</span>) }
      end

      # Replace user @mentions in text with HTML tags.
      #
      # text              - String text to replace @mention in.
      # username_pattern  - Regular expression used to identify usernames in
      #                     text
      # Returns a string with @mentions replaced with HTML tags.
      def mention_tag_filter(text, username_pattern = USERNAME_PATTERN)
        self.class.mentioned_usernames_in(text, username_pattern) do |match, mention, attention, _index|
          result[:mentions] |= [mention]
          result[:attentions] |= [attention]

          mention_tag = if mention_validator.call(mention)
                          mention_tag_buider.call(mention)
                        else
                          "@#{mention}"
                        end
          attention_tag = attention_tag_buider.call(attention, mention) if attention

          link = mention_tag ? match.sub("@#{mention}", mention_tag) : match
          attention_tag ? link.sub("!#{attention}", " #{attention_tag}") : link
        end
      end
    end
  end
end
