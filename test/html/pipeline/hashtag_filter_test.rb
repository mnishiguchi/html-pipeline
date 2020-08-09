# frozen_string_literal: true

require 'test_helper'
require 'html/pipeline/hashtag_filter'

class HTML::Pipeline::HashtagFilterTest < Minitest::Test
  Filter = HTML::Pipeline::HashtagFilter

  def test_filtering_a_documentfragment
    body = '<p>#happy-coding: check it out.</p>'
    doc  = Nokogiri::HTML::DocumentFragment.parse(body)

    res = Filter.call(doc)
    assert_same(doc, res)

    html_tag = '<span class="hashtag-happy-coding">happy-coding</span>'
    assert_equal "<p>#{html_tag}: check it out.</p>",
                 res.to_html
  end

  def test_filtering_plain_text
    body = '<p>#happy-coding: check it out.</p>'
    res = Filter.call(body)

    html_tag = '<span class="hashtag-happy-coding">happy-coding</span>'
    assert_equal "<p>#{html_tag}: check it out.</p>",
                 res.to_html
  end

  def test_not_replacing_hashtags_in_pre_tags
    body = '<pre>#happy-coding: okay</pre>'
    assert_equal body, Filter.call(body).to_html
  end

  def test_not_replacing_hashtags_in_code_tags
    body = '<p><code>#happy-coding:</code> okay</p>'
    assert_equal body, Filter.call(body).to_html
  end

  def test_not_replacing_hashtags_in_links
    body = '<p><a>#happy-coding</a> okay</p>'
    assert_equal body, Filter.call(body).to_html
  end

  def test_entity_encoding_and_whatnot
    body = "<p>#&#104;appy-coding what's up</p>"
    html_tag = '<span class="hashtag-happy-coding">happy-coding</span>'
    assert_equal "<p>#{html_tag} what's up</p>", Filter.call(body).to_html
  end

  def test_html_injection
    body = '<p>#happy-coding &lt;script>alert(0)&lt;/script></p>'
    html_tag = '<span class="hashtag-happy-coding">happy-coding</span>'
    assert_equal "<p>#{html_tag} &lt;script&gt;alert(0)&lt;/script&gt;</p>",
                 Filter.call(body).to_html
  end

  MarkdownPipeline = HTML::Pipeline.new [
    HTML::Pipeline::MarkdownFilter,
    HTML::Pipeline::HashtagFilter
  ]

  def matched_hashtags
    result = {}
    MarkdownPipeline.call(@body, {}, result)
    result[:hashtags]
  end

  def hashtaged_attentions
    result = {}
    MarkdownPipeline.call(@body, {}, result)
    result[:attentions]
  end

  def test_matches_hashtags_in_body
    @body = '#test how are you?'
    assert_equal %w[test], matched_hashtags
  end

  # def test_matches_colon_suffixed_names
  #   @body = '#tmm1: what do you think?'
  #   assert_equal %w[tmm1], matched_hashtags
  # end

  def test_matches_list_of_names
    @body = '#defunkt #atmos #happy-coding'
    assert_equal %w[defunkt atmos happy-coding], matched_hashtags
  end

  def test_matches_list_of_names_with_commas
    @body = '/cc #defunkt, #atmos, #happy-coding'
    assert_equal %w[defunkt atmos happy-coding], matched_hashtags
  end

  def test_matches_inside_brackets
    @body = '(#mislav) and [#rtomayko]'
    assert_equal %w[mislav rtomayko], matched_hashtags
  end

  def test_doesnt_ignore_invalid_hashtags
    @body = '#defunkt #mojombo and #somedude'
    assert_equal %w[defunkt mojombo somedude], matched_hashtags
  end

  def test_returns_distinct_set
    @body = '#defunkt, #atmos, #happy-coding, #defunkt, #defunkt'
    assert_equal %w[defunkt atmos happy-coding], matched_hashtags
  end

  def test_does_not_match_inline_code_block_with_multiple_code_blocks
    @body = "something\n\n`#defunkt #atmos #happy-coding` `#atmos/atmos`"
    assert_equal %w[], matched_hashtags
  end

  def test_hashtag_at_end_of_parenthetical_sentence
    @body = "(We're talking 'bout #ymendel.)"
    assert_equal %w[ymendel], matched_hashtags
  end
end
