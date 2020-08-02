# frozen_string_literal: true

require 'test_helper'
require 'html/pipeline/whitespece_filter'

class HTML::Pipeline::WhitespaceFilterTest < Minitest::Test
  WhitespaceFilter = ::HTML::Pipeline::WhitespaceFilter

  def test_wrap_paragraph_in_p_tag_for_plain_html_text
    div_with_newline_chars = <<~HTML.strip
      <div>header


      body
      content

      footer</div>
    HTML
    document_fragment = Nokogiri::HTML::DocumentFragment.parse(div_with_newline_chars)

    expected = "<div>\n<p>header</p>\n<p>body<br>content</p>\n<p>footer</p>\n</div>"
    assert_equal(expected, WhitespaceFilter.call(div_with_newline_chars).to_html)
    assert_equal(expected, WhitespaceFilter.call(document_fragment).to_html)
  end

  def test_ignore_certain_tags
    ignored_tags = %w[pre code p]
    html_text = ->(tag) { "<#{tag}>foo\n\nbar\nbaz</#{tag}>" }

    ignored_tags.each do |tag|
      assert_equal(html_text[tag], WhitespaceFilter.call(html_text[tag]).to_html)
    end
  end

  def test_translate_newline_to_br_for_q
    q_with_newline_chars = "<q>foo\n\nbar\nbaz</q>"
    expected = "<q>foo<br><br>bar<br>baz</q>"

    assert_equal(expected, WhitespaceFilter.call(q_with_newline_chars).to_html)
  end

  def test_pipeline_text_with_no_whitespace

    assert_equal(
      "<div>foo</div>",
      plain_text_pipeline.call("foo").fetch(:output).to_html
    )
  end

  def test_pipeline_text_with_one_linebreak
    assert_equal(
      "<div>foo<br>bar</div>",
      plain_text_pipeline.call("foo\nbar").fetch(:output).to_html
    )
  end

  def test_pipeline_text_with_two_linebreak
    assert_equal(
      "<div>\n<p>foo</p>\n<p>bar</p>\n</div>",
      plain_text_pipeline.call("foo\n\nbar").fetch(:output).to_html
    )
  end

  def test_pipeline_text_with_three_linebreak
    assert_equal(
      "<div>\n<p>foo</p>\n<p>bar</p>\n</div>",
      plain_text_pipeline.call("foo\n\n\nbar").fetch(:output).to_html
    )
  end

  def test_pipeline_text_with_one_linebreak_two_linebreak_mixed
    assert_equal(
      "<div>\n<p>foo</p>\n<p>bar<br>baz</p>\n</div>",
      plain_text_pipeline.call("foo\n\nbar\nbaz").fetch(:output).to_html
    )
  end

  private

  def plain_text_pipeline
    HTML::Pipeline.new [
      HTML::Pipeline::PlainTextInputFilter,
      HTML::Pipeline::WhitespaceFilter,
    ]
  end
end
