# frozen_string_literal: true

require 'tracking_number'
require 'addressable/template'

module HTML
  class Pipeline
    # HTML filter that auto-links any identifiable Tracking Number
    # Numbers within <PRE>, <CODE>, <A>, and <Q> elements are ignored.
    #
    # Context options:
    #   :tracking_number_link_attributes - An attributes hash for the tracking link tags.
    class TrackingNumberFilter < Filter
      UPS_URL    = Addressable::Template.new('http://wwwapps.ups.com/WebTracking/track?loc=en_US&trackNums={number}&track.x=Track')
      FEDEX_URL  = Addressable::Template.new('https://www.fedex.com/fedextrack/?tracknumbers={number}&cntry_code=us')
      ONTRAC_URL = Addressable::Template.new('https://www.ontrac.com/trackingres.asp?tracking_number={number}')

      IGNORE_PARENTS = %w[pre code a q].freeze

      def call
        doc.search('.//text()').each do |node|
          content = node.to_html
          next unless content =~ /\d+/
          next if has_ancestor?(node, IGNORE_PARENTS)

          new_node = content_with_tracking_links(content)
          next if new_node == content

          node.replace(new_node)
        end
        doc
      end

      private

      # Detects tracking numbers in the text and replace them with link tags.
      def content_with_tracking_links(text)
        text = text.dup
        TrackingNumber.search(text).each do |tracking_number|
          text.gsub! tracking_number.to_s, tracking_number_tag(tracking_number)
        end

        text
      end

      # If the tracking URL is generated successfully, returns a <A/> tag. Else
      # returns a <SPAN/> tag.
      def tracking_number_tag(tracking_number)
        carrier = tracking_number.carrier
        tracking_url = url_for(carrier, tracking_number)
        html_tag = tracking_url ? '<a/>' : '<span/>'
        node = Nokogiri::HTML::DocumentFragment.parse(html_tag).children.first
        link_attributes.each { |k, v| node.set_attribute(k, v) }
        node.set_attribute(:href, tracking_url) if tracking_url
        node.add_child(Nokogiri::XML::Text.new(tracking_number.to_s, node))
        node.to_html
      end

      def url_for(carrier, tracking_number)
        send("url_for_#{carrier}", tracking_number)
      end

      def url_for_ups(number)
        UPS_URL.expand(number: number.tracking_number)
      end

      def url_for_fedex(number)
        FEDEX_URL.expand(number: number.tracking_number)
      end

      def url_for_ontrac(number)
        ONTRAC_URL.expand(number: number.tracking_number)
      end

      def link_attributes
        context[:tracking_number_link_attributes]  || { class: 'tracking-number' }
      end
    end
  end
end
