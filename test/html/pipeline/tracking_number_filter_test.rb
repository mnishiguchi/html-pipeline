# frozen_string_literal: true

require 'test_helper'
require 'html/pipeline/tracking_number_filter'

class HTML::Pipeline::TrackingNumberFilterTest < Minitest::Test
  TrackingNumberFilter = ::HTML::Pipeline::TrackingNumberFilter

  def test_include_tracking_number_tag
    plain_text = '<p>1ZA03R690394992556</p>'
    document_fragment = Nokogiri::HTML::DocumentFragment.parse(plain_text)

    expected = '<p><a class="tracking-number" href="http://wwwapps.ups.com/WebTracking/track?loc=en_US&amp;trackNums=1ZA03R690394992556&amp;track.x=Track">1ZA03R690394992556</a></p>'
    assert_equal(expected, TrackingNumberFilter.call(plain_text).to_html)
    assert_equal(expected, TrackingNumberFilter.call(document_fragment).to_html)
  end

  def test_ignore_certain_tags
    ignored_tags = %w[pre code q]
    html_text = ->(tag) { "<#{tag}>1ZA03R690394992556</#{tag}>" }

    ignored_tags.each do |tag|
      assert_equal(html_text[tag], TrackingNumberFilter.call(html_text[tag]).to_html)
    end
  end

  def test_context
    context = {
      tracking_number_link_attributes: {
        'class' => 'my-custom-class',
        'data-something' => 'hello'
      }
    }
    assert_equal(
      '<a class="my-custom-class" data-something="hello" href="http://wwwapps.ups.com/WebTracking/track?loc=en_US&amp;trackNums=1ZA03R690394992556&amp;track.x=Track">1ZA03R690394992556</a>',
      TrackingNumberFilter.call('1ZA03R690394992556', context).to_html
    )
  end

  def test_ignore_unidentifiable_number
    unidentifiable_number = 'xxxxxxxx'
    assert_equal(unidentifiable_number, TrackingNumberFilter.call(unidentifiable_number).to_html)
  end

  def test_pipeline_markdown_with_no_number
    assert_equal(
      '<p>foo bar-bar baz</p>',
      markdown_pipeline.call('foo bar-bar baz').fetch(:output).to_html
    )
  end

  def test_pipeline_markdown_with_ups_number
    assert_equal(
      '<p>shipped <a class="tracking-number" href="http://wwwapps.ups.com/WebTracking/track?loc=en_US&amp;trackNums=1ZA03R690394992556&amp;track.x=Track">1ZA03R690394992556</a></p>',
      markdown_pipeline.call('shipped 1ZA03R690394992556').fetch(:output).to_html
    )
  end

  def test_pipeline_markdown_with_fedex_number
    assert_equal(
      '<p>shipped <a class="tracking-number" href="https://www.fedex.com/fedextrack/?tracknumbers=9612015453550870985504&amp;cntry_code=us">9612015453550870985504</a></p>',
      markdown_pipeline.call('shipped 9612015453550870985504').fetch(:output).to_html
    )
  end

  def test_pipeline_markdown_with_ontrac_number
    assert_equal(
      '<p>shipped <a class="tracking-number" href="https://www.ontrac.com/trackingres.asp?tracking_number=C10489811867665">C10489811867665</a></p>',
      markdown_pipeline.call('shipped C10489811867665').fetch(:output).to_html
    )
  end

  private

  def markdown_pipeline(context = {})
    HTML::Pipeline.new [
      HTML::Pipeline::MarkdownFilter,
      HTML::Pipeline::TrackingNumberFilter
    ], context
  end
end
