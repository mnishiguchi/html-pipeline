# frozen_string_literal: true

require 'bundler/setup'
require 'html/pipeline'
require 'minitest/autorun'
require 'minitest/pride'
require 'minitest/focus'

require 'active_support/core_ext/string'
require 'pry'

module TestHelpers
  # Asserts that two html fragments are equivalent. Attribute order
  # will be ignored.
  def assert_equal_html(expected, actual)
    assert_equal Nokogiri::HTML::DocumentFragment.parse(expected).to_hash,
                 Nokogiri::HTML::DocumentFragment.parse(actual).to_hash
  end
end

Minitest::Test.send(:include, TestHelpers)
