require "test_helper"

class NavigationItem::SocialPlatformTest < ActiveSupport::TestCase
  def platform_for(url)
    NavigationItem.new(url: url).social_platform
  end

  test "detects platforms from known hosts" do
    {
      "https://x.com/prose" => :x,
      "https://twitter.com/prose" => :x,
      "https://www.github.com/prose" => :github,
      "https://www.linkedin.com/in/prose" => :linkedin,
      "https://bsky.app/profile/prose.bsky.social" => :bluesky,
      "https://youtu.be/abc" => :youtube,
      "https://m.youtube.com/@prose" => :youtube,
      "https://instagram.com/prose" => :instagram,
      "https://facebook.com/prose" => :facebook,
      "https://www.threads.net/@prose" => :threads,
      "https://mastodon.social/@prose" => :mastodon
    }.each do |url, platform|
      assert_equal platform, platform_for(url), url
    end
  end

  test "detects self-hosted Mastodon profiles by path shape" do
    assert_equal :mastodon, platform_for("https://social.example.org/@prose")
  end

  test "detects feeds" do
    assert_equal :rss, platform_for("https://example.com/feed.xml")
    assert_equal :rss, platform_for("https://example.com/rss")
  end

  test "does not match lookalike hosts" do
    assert_equal :website, platform_for("https://notgithub.com/prose")
  end

  test "falls back to website for unknown or unparseable URLs" do
    assert_equal :website, platform_for("https://example.com")
    assert_equal :website, platform_for("https://exa mple.com")
  end

  test "every platform has an icon" do
    NavigationItem::SocialPlatform::PLATFORMS.each do |platform|
      assert NavigationHelper::SOCIAL_ICONS.key?(platform), platform
    end
  end
end
