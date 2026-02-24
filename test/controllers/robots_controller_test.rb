require "test_helper"

class RobotsControllerTest < ActionDispatch::IntegrationTest
  test "GET robots.txt renders plain text" do
    get "/robots.txt"
    assert_response :success
    assert_equal "text/plain; charset=utf-8", response.content_type
  end

  test "robots.txt contains standard directives when crawlers allowed" do
    SiteSetting.current.update!(block_crawlers: false)
    get "/robots.txt"
    assert_includes response.body, "User-agent: *"
    assert_includes response.body, "Allow: /"
    assert_includes response.body, "Disallow: /admin/"
    assert_includes response.body, "Disallow: /mcp"
    assert_includes response.body, sitemap_url(format: :xml)
  end

  test "robots.txt blocks all crawlers when setting enabled" do
    SiteSetting.current.update!(block_crawlers: true)
    get "/robots.txt"
    assert_includes response.body, "User-agent: *"
    assert_includes response.body, "Disallow: /"
    assert_not_includes response.body, "Allow: /"
    assert_not_includes response.body, "Disallow: /admin/"
    assert_includes response.body, sitemap_url(format: :xml)
  end
end
