require "test_helper"

class ReferrerParserTest < ActiveSupport::TestCase
  test "extracts UTM params from referrer" do
    result = ReferrerParser.call("https://example.com/page?utm_source=newsletter&utm_medium=email&utm_campaign=launch")

    assert_equal "other", result[:source]
    assert_equal "example.com", result[:domain]
    assert_equal "newsletter", result[:utm_source]
    assert_equal "email", result[:utm_medium]
    assert_equal "launch", result[:utm_campaign]
  end

  test "extracts domain without www prefix" do
    result = ReferrerParser.call("https://www.google.com/search?q=test")

    assert_equal "google.com", result[:domain]
    assert_equal "google", result[:source]
  end

  test "handles blank referrer as direct" do
    result = ReferrerParser.call(nil)

    assert_equal "direct", result[:source]
    assert_nil result[:domain]
    assert_nil result[:utm_source]
  end

  test "handles invalid URI gracefully" do
    result = ReferrerParser.call("not a valid uri %%")

    assert_equal "other", result[:source]
    assert_nil result[:domain]
  end

  test "truncates long UTM values" do
    long_campaign = "x" * 300

    result = ReferrerParser.call("https://example.com?utm_campaign=#{long_campaign}")

    assert result[:utm_campaign].length <= 255
  end

  test "extracts twitter source from x.com" do
    result = ReferrerParser.call("https://x.com/user/status/123")

    assert_equal "twitter", result[:source]
    assert_equal "x.com", result[:domain]
  end

  test "referrer with no query params has nil UTM fields" do
    result = ReferrerParser.call("https://www.reddit.com/r/rails")

    assert_equal "reddit", result[:source]
    assert_nil result[:utm_source]
    assert_nil result[:utm_medium]
    assert_nil result[:utm_campaign]
  end
end
