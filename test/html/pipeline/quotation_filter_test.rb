# frozen_string_literal: true

require 'test_helper'
require 'html/pipeline/quotation_filter'

class HTML::Pipeline::QuotationFilterTest < Minitest::Test
  QuotationFilter = ::HTML::Pipeline::QuotationFilter

  def test_wrap_paragraph_in_p_tag_for_plain_html_text
    div_with_quoted_text = %(<div>foo "quote\ncontent" bar</div>)
    document_fragment = Nokogiri::HTML::DocumentFragment.parse(div_with_quoted_text)

    expected = %(<div>foo <q>quote\ncontent</q> bar</div>)
    assert_equal(expected, QuotationFilter.call(div_with_quoted_text).to_html)
    assert_equal(expected, QuotationFilter.call(document_fragment).to_html)
  end

  def test_ignore_certain_tags
    ignored_tags = %w[pre code q]
    html_text = ->(tag) { %(<#{tag}>foo "quote\ncontent" bar</#{tag}>) }

    ignored_tags.each do |tag|
      assert_equal(html_text[tag], QuotationFilter.call(html_text[tag]).to_html)
    end
  end

  def test_ignore_words_ending_with_quotation
    text = %(the value 12.5" and 14" are in inches)
    assert_equal(text, QuotationFilter.call(text).to_html)
  end

  def test_beginning_of_string
    text = %("bar" baz)
    assert_equal %(<q>bar</q> baz),
                 QuotationFilter.call(text).to_html
  end

  def test_with_line_break
    text = %(foo "bar\n123" baz)
    assert_equal %(foo <q>bar\n123</q> baz),
                 QuotationFilter.call(text).to_html
  end

  def test_with_line_break_and_carriage_return
    text = %(foo "bar\r\n123" baz)
    assert_equal %(foo <q>bar\r\n123</q> baz),
                 QuotationFilter.call(text).to_html
  end

  def test_single_quoted_word
    text = %(foo "bar" baz)
    assert_equal %(foo <q>bar</q> baz),
                 QuotationFilter.call(text).to_html
  end

  def test_multiple_quoted_word
    text = %(foo \"bar\" \"baz\" qux)
    assert_equal %(foo <q>bar</q> <q>baz</q> qux),
                 QuotationFilter.call(text).to_html
  end

  def test_quote_mismatch
    text = %(foo "bar"" baz)
    assert_equal %(foo <q>bar</q>" baz),
                 QuotationFilter.call(text).to_html
  end
end
