# frozen_string_literal: true

require 'test_helper'
require 'html/pipeline/numerical_word_filter'

class HTML::Pipeline::NumericalWordFilterTest < Minitest::Test
  Filter = HTML::Pipeline::NumericalWordFilter

  def test_filtering_a_documentfragment
    body = '<p>123 check it out.</p>'
    doc  = Nokogiri::HTML::DocumentFragment.parse(body)

    res = Filter.call(doc)
    assert_same(doc, res)

    html_tag = '<span class="numerical-word-123">123</span>'
    assert_equal "<p>#{html_tag} check it out.</p>",
                 res.to_html
  end

  def test_filtering_plain_text
    body = '<p>123 check it out.</p>'
    res = Filter.call(body)

    html_tag = '<span class="numerical-word-123">123</span>'
    assert_equal "<p>#{html_tag} check it out.</p>",
                 res.to_html
  end

  def test_not_replacing_numerical_words_in_pre_tags
    body = '<pre>123 okay</pre>'
    assert_equal body, Filter.call(body).to_html
  end

  def test_not_replacing_numerical_words_in_code_tags
    body = '<p><code>123</code> okay</p>'
    assert_equal body, Filter.call(body).to_html
  end

  # def test_not_replacing_numerical_words_in_links
  #   body = '<p><a>123</a> okay</p>'
  #   assert_equal body, Filter.call(body).to_html
  # end

  def test_entity_encoding_and_whatnot
    body = "<p>&#49;&#50;&#51; what's up</p>"
    html_tag = '<span class="numerical-word-123">123</span>'
    assert_equal "<p>#{html_tag} what's up</p>", Filter.call(body).to_html
  end

  MarkdownPipeline = HTML::Pipeline.new [
    HTML::Pipeline::MarkdownFilter,
    HTML::Pipeline::NumericalWordFilter
  ]

  def matched_numerical_words
    result = {}
    MarkdownPipeline.call(@body, {}, result)
    result[:numerical_words]
  end

  def test_matches_small_integer_dollar_price
    @body = 'refunded $123'
    assert_equal %w[$123], matched_numerical_words
  end

  def test_matches_small_integer_dollar_price_followed_by_dot
    @body = 'refunded $123.'
    assert_equal %w[$123], matched_numerical_words
  end

  def test_matches_small_integer_dollar_price_followed_by_ellipsis
    @body = 'refunded $123...'
    assert_equal %w[$123], matched_numerical_words
  end

  def test_matches_large_integer_dollar_price
    @body = 'refunded $123,456'
    assert_equal %w[$123,456], matched_numerical_words
  end

  def test_matches_large_integer_dollar_price_followed_by_comma
    @body = 'refunded $123,456,'
    assert_equal %w[$123,456], matched_numerical_words
  end

  def test_matches_large_integer_dollar_price_followed_by_ellipsis
    @body = 'refunded $123,456...'
    assert_equal %w[$123,456], matched_numerical_words
  end

  def test_matches_small_decimal_dollar_price
    @body = 'refunded $123.45'
    assert_equal %w[$123.45], matched_numerical_words
  end

  def test_matches_small_decimal_dollar_price_followed_by_dot
    @body = 'refunded $123.45.'
    assert_equal %w[$123.45], matched_numerical_words
  end

  def test_matches_small_decimal_dollar_price_followed_by_ellipsis
    @body = 'refunded $123.45...'
    assert_equal %w[$123.45], matched_numerical_words
  end

  def test_matches_large_decimal_dollar_price
    @body = 'refunded $123,456.78'
    assert_equal %w[$123,456.78], matched_numerical_words
  end

  def test_matches_large_decimal_dollar_price_followed_by_dot
    @body = 'refunded $123,456.78.'
    assert_equal %w[$123,456.78], matched_numerical_words
  end

  def test_matches_large_decimal_dollar_price_followed_by_ellipsis
    @body = 'refunded $123,456.78...'
    assert_equal %w[$123,456.78], matched_numerical_words
  end

  def test_matches_numerical_words_with_dashes
    @body = 'Call 703-123-4567 now'
    assert_equal %w[703-123-4567], matched_numerical_words
  end

  def test_matches_numerical_words_with_dots
    @body = 'Call 703.123.4567 now'
    assert_equal %w[703.123.4567], matched_numerical_words
  end

  def test_matches_list_of_numerical_words
    @body = '111 222 333'
    assert_equal %w[111 222 333], matched_numerical_words
  end

  def test_matches_list_of_numerical_words_with_commas
    @body = '111, 222, 333, ...'
    assert_equal %w[111 222 333], matched_numerical_words
  end

  def test_matches_inside_brackets
    @body = '(111) and [222]'
    assert_equal %w[(111) [222]], matched_numerical_words
  end

  def test_matches_prefixed_with_comma
    @body = 'xxx foo,123 xxx'
    assert_equal %w[123], matched_numerical_words
  end

  def test_matches_prefixed_with_plus
    @body = 'xxx +123 xxx'
    assert_equal %w[+123], matched_numerical_words
  end

  def test_matches_prefixed_with_tilde
    @body = 'xxx ~123 xxx'
    assert_equal %w[~123], matched_numerical_words
  end

  def test_matches_prefixed_with_exclamation
    @body = 'xxx !123 xxx'
    assert_equal %w[!123], matched_numerical_words
  end

  def test_matches_prefixed_with_pound
    @body = 'xxx #123 xxx'
    assert_equal %w[#123], matched_numerical_words
  end

  def test_matches_prefixed_with_minus
    @body = 'xxx -123 xxx'
    assert_equal %w[-123], matched_numerical_words
  end

  def test_matches_prefixed_with_word
    @body = 'xxx foo123 xxx'
    assert_equal %w[foo123], matched_numerical_words
  end

  def test_matches_suffixed_with_word
    @body = 'xxx 123bar xxx'
    assert_equal %w[123bar], matched_numerical_words
  end

  def test_matches_suffixed_with_dot
    @body = 'xxx 123.bar xxx'
    assert_equal %w[123], matched_numerical_words
  end

  def test_matches_suffixed_with_exclamation
    @body = 'xxx 123! xxx'
    assert_equal %w[123!], matched_numerical_words
  end

  def test_matches_suffixed_with_colon
    @body = 'xxx 123: xxx'
    assert_equal %w[123:], matched_numerical_words
  end

  def test_matches_suffixed_with_slach
    @body = 'xxx 123/xxx'
    assert_equal %w[123], matched_numerical_words
  end

  def test_returns_distinct_set
    @body = '111, 222, 333, 222, 111'
    assert_equal %w[111 222 333], matched_numerical_words
  end

  def test_does_not_match_inline_code_block_with_multiple_code_blocks
    @body = "something\n\n`111` `222`"
    assert_equal %w[], matched_numerical_words
  end

  def test_numerical_word_at_end_of_parenthetical_sentence
    @body = "(We're talking 'bout 123.)"
    assert_equal %w[123], matched_numerical_words
  end
end
