# frozen_string_literal: true

require 'test_helper'
require 'html/pipeline/mention_attention_filter'

class HTML::Pipeline::MentionAttentionFilterTest < Minitest::Test
  Filter = HTML::Pipeline::MentionAttentionFilter

  def test_filtering_a_documentfragment
    body = '<p>@kneath: check it out.</p>'
    doc  = Nokogiri::HTML::DocumentFragment.parse(body)

    res = Filter.call(doc)
    assert_same(doc, res)

    html_tag = '<span class="mention-kneath">kneath</span>'
    assert_equal "<p>#{html_tag}: check it out.</p>",
                 res.to_html
  end

  def test_filtering_plain_text
    body = '<p>@kneath: check it out.</p>'
    res = Filter.call(body)

    html_tag = '<span class="mention-kneath">kneath</span>'
    assert_equal "<p>#{html_tag}: check it out.</p>",
                 res.to_html
  end

  def test_not_replacing_mentions_in_pre_tags
    body = '<pre>@kneath: okay</pre>'
    assert_equal body, Filter.call(body).to_html
  end

  def test_not_replacing_mentions_in_code_tags
    body = '<p><code>@kneath:</code> okay</p>'
    assert_equal body, Filter.call(body).to_html
  end

  def test_not_replacing_mentions_in_style_tags
    body = '<style>@media (min-width: 768px) { color: red; }</style>'
    assert_equal body, Filter.call(body).to_html
  end

  def test_not_replacing_mentions_in_links
    body = '<p><a>@kneath</a> okay</p>'
    assert_equal body, Filter.call(body).to_html
  end

  def test_entity_encoding_and_whatnot
    body = "<p>@&#x6b;neath what's up</p>"
    html_tag = '<span class="mention-kneath">kneath</span>'
    assert_equal "<p>#{html_tag} what's up</p>", Filter.call(body).to_html
  end

  def test_html_injection
    body = '<p>@kneath &lt;script>alert(0)&lt;/script></p>'
    html_tag = '<span class="mention-kneath">kneath</span>'
    assert_equal "<p>#{html_tag} &lt;script&gt;alert(0)&lt;/script&gt;</p>",
                 Filter.call(body).to_html
  end

  MarkdownPipeline = HTML::Pipeline.new [
    HTML::Pipeline::MarkdownFilter,
    HTML::Pipeline::MentionAttentionFilter
  ]

  def mentioned_usernames
    result = {}
    MarkdownPipeline.call(@body, {}, result)
    result[:mentions]
  end

  def mentioned_attentions
    result = {}
    MarkdownPipeline.call(@body, {}, result)
    result[:attentions]
  end

  def test_matches_usernames_in_body
    @body = '@test how are you?'
    assert_equal %w[test], mentioned_usernames
  end

  def test_matches_attentions_in_body
    @body = '@test!important how are you?'
    assert_equal %w[important], mentioned_attentions
  end

  def test_does_not_match_standalone_attentions_in_body
    @body = '!important !nice!bad'
    assert_equal [], mentioned_attentions
  end

  # def test_matches_usernames_with_dashes
  #   @body = 'hi @some-user'
  #   assert_equal %w[some-user], mentioned_usernames
  # end

  # def test_matches_usernames_followed_by_a_single_dot
  #   @body = 'okay @some-user.'
  #   assert_equal %w[some-user], mentioned_usernames
  # end

  # def test_matches_usernames_followed_by_multiple_dots
  #   @body = 'okay @some-user...'
  #   assert_equal %w[some-user], mentioned_usernames
  # end

  def test_does_not_match_email_addresses
    @body = 'aman@tmm1.net'
    assert_equal [], mentioned_usernames
  end

  def test_does_not_match_domain_name_looking_things
    @body = 'we need a @github.com email'
    assert_equal [], mentioned_usernames
  end

  def test_does_not_match_organization_team_mentions
    @body = 'we need to @github/enterprise know'
    assert_equal [], mentioned_usernames
  end

  def test_matches_colon_suffixed_names
    @body = '@tmm1: what do you think?'
    assert_equal %w[tmm1], mentioned_usernames
  end

  def test_matches_list_of_names
    @body = '@defunkt @atmos @kneath'
    assert_equal %w[defunkt atmos kneath], mentioned_usernames
  end

  def test_matches_list_of_names_with_commas
    @body = '/cc @defunkt, @atmos, @kneath'
    assert_equal %w[defunkt atmos kneath], mentioned_usernames
  end

  def test_matches_inside_brackets
    @body = '(@mislav) and [@rtomayko]'
    assert_equal %w[mislav rtomayko], mentioned_usernames
  end

  def test_doesnt_ignore_invalid_users
    @body = '@defunkt @mojombo and @somedude'
    assert_equal %w[defunkt mojombo somedude], mentioned_usernames
  end

  def test_returns_distinct_set
    @body = '/cc @defunkt, @atmos, @kneath, @defunkt, @defunkt'
    assert_equal %w[defunkt atmos kneath], mentioned_usernames
  end

  def test_does_not_match_inline_code_block_with_multiple_code_blocks
    @body = "something\n\n`/cc @defunkt @atmos @kneath` `/cc @atmos/atmos`"
    assert_equal %w[], mentioned_usernames
  end

  def test_mention_at_end_of_parenthetical_sentence
    @body = "(We're talking 'bout @ymendel.)"
    assert_equal %w[ymendel], mentioned_usernames
  end

  def test_username_pattern_can_be_customized
    body = '<p>@_abc: test.</p>'
    doc  = Nokogiri::HTML::DocumentFragment.parse(body)

    res  = Filter.call(doc, username_pattern: /(_[a-z]{3})/)

    html_tag = '<span class="mention-_abc">_abc</span>'
    assert_equal "<p>#{html_tag}: test.</p>",
                 res.to_html
  end
end
