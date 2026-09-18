require "test_helper"

class SitemapsControllerTest < ActionDispatch::IntegrationTest
  test "GET index renders sitemap XML" do
    get sitemap_path(format: :xml)
    assert_response :success
    assert_equal "application/xml; charset=utf-8", response.content_type
    assert_includes response.body, post_url(slug: posts(:published_post).slug)
  end

  test "sitemap does not include draft posts" do
    get sitemap_path(format: :xml)
    assert_not_includes response.body, posts(:draft_post).slug
  end

  test "sitemap uses plain post, category and tag URLs" do
    get sitemap_path(format: :xml)
    { "posts" => posts(:published_post), "categories" => categories(:technology), "tags" => tags(:ruby) }.each do |prefix, record|
      assert_match %r{<loc>http://[^<]+/#{prefix}/#{record.slug}</loc>}, response.body
      assert_no_match(/#{record.slug}\.#{record.slug}/, response.body)
    end
  end
end
