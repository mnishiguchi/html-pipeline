module HTML
  class Pipeline
    # HTML filter that wraps all quoted strings with Q tags.
    # Strings within <p>, <pre>, and <code> elements are ignored.
    class QuotationFilter < Filter
      QuotationPattern = /
        (?<=\A|\s) # The start of the string or at least one leading space
        "[^"]*"    # Anything enclosed in quotation marks
      /ix.freeze

      # Don't look for linefeeds in text nodes that are children of these elements
      IGNORE_PARENTS = %w[pre code q].to_set

      def call
        doc.search('.//text()').each do |node|
          content = node.to_html
          next if !content =~ /"+/
          next if has_ancestor?(node, IGNORE_PARENTS)

          html = quotation_filter(content)
          next if html == content

          node.replace(html)
        end
        doc
      end

      # Replaces all quoted strings with a Q tag, removing any double-quotes
      #
      # text      - String text to replace quotations in.
      #
      # Returns a string with quotations replaced with Q tags.
      def quotation_filter(text)
        text.gsub QuotationPattern do |w|
          wrap_result w.gsub('"', '')
        end
      end

      # Wraps the quoted text in Q tags if a matching pair of quotation marks
      # are present
      def wrap_result(text)
        "<q>#{text}</q>"
      end
    end
  end
end
