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

  test "classifies exact hosts and subdomains of known sources" do
    {
      "https://x.com/user" => "twitter",
      "https://twitter.com/user" => "twitter",
      "https://mobile.twitter.com/user" => "twitter",
      "https://t.co/abc123" => "twitter",
      "https://www.facebook.com/post" => "facebook",
      "https://lnkd.in/abc" => "linkedin",
      "https://www.linkedin.com/feed" => "linkedin",
      "https://old.reddit.com/r/rails" => "reddit",
      "https://news.ycombinator.com/item?id=1" => "hackernews",
      "https://www.google.com/search" => "google",
      "https://www.google.co.uk/search" => "google"
    }.each do |referrer, expected|
      assert_equal expected, ReferrerParser.call(referrer)[:source], "expected #{referrer} to be #{expected}"
    end
  end

  test "does not classify hosts that merely contain a source name or substring" do
    %w[
      https://dropbox.com/s/abc
      https://netflix.com/title/1
      https://wix.com/site
      https://box.com/file
      https://xyz.com/page
      https://notx.com/page
      https://nt.co/page
      https://john.example/post
      https://hn.example.com/post
      https://mygoogle.com/page
      https://google.evil.com/page
      https://redditor.example/page
      https://myfacebook.com/page
    ].each do |referrer|
      assert_equal "other", ReferrerParser.call(referrer)[:source], "expected #{referrer} to be other"
    end
  end

  test "referrer with no query params has nil UTM fields" do
    result = ReferrerParser.call("https://www.reddit.com/r/rails")

    assert_equal "reddit", result[:source]
    assert_nil result[:utm_source]
    assert_nil result[:utm_medium]
    assert_nil result[:utm_campaign]
  end
end
