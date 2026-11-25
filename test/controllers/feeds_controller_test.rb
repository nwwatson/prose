require "test_helper"

class FeedsControllerTest < ActionDispatch::IntegrationTest
  test "GET index renders RSS feed" do
    get feed_path(format: :xml)
    assert_response :success
    assert_equal "application/xml; charset=utf-8", response.content_type
    assert_includes response.body, posts(:published_post).title
  end

  test "RSS feed does not include draft posts" do
    get feed_path(format: :xml)
    assert_not_includes response.body, posts(:draft_post).title
  end

  test "GET index preloads author identities in a single query" do
    assert_query_count(1, table: "identities") { get feed_path(format: :xml) }
  end

  test "RSS item link and guid use the plain post URL" do
    get feed_path(format: :xml)
    slug = posts(:published_post).slug
    assert_match %r{<link>http://[^<]+/posts/#{slug}</link>}, response.body
    assert_match %r{<guid>http://[^<]+/posts/#{slug}</guid>}, response.body
    assert_no_match(/#{slug}\.#{slug}/, response.body)
  end

  test "RSS feed includes the full body of public posts" do
    publish_with_body(posts(:published_post), visibility: :public)

    get feed_path(format: :xml)

    assert_includes feed_item(posts(:published_post)).at_xpath("content:encoded").text, "SECRET-BODY"
  end

  %i[members_only paid_only].each do |visibility|
    test "RSS feed sends only a teaser for #{visibility} posts" do
      post = posts(:published_post)
      publish_with_body(post, visibility: visibility)

      get feed_path(format: :xml)

      assert_not_includes response.body, "SECRET-BODY"
      encoded = feed_item(post).at_xpath("content:encoded").text
      assert_includes encoded, "A public teaser"
      assert_includes encoded, "/posts/#{post.slug}"
      assert_includes encoded, I18n.t("feeds.read_more", site: SiteSetting.current.site_name)
    end
  end

  private

  # The marker sits past the 155-character excerpt that seo_description falls
  # back to, so only the full body can contain it.
  def publish_with_body(post, visibility:)
    post.update!(visibility: visibility, meta_description: "A public teaser",
                 content: "<p>#{"Opening words. " * 30}</p><p>SECRET-BODY</p>")
  end

  def feed_item(post)
    Nokogiri::XML(response.body).xpath("//item").find { |item| item.at_xpath("title").text == post.title }
  end
end
