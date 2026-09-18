require "test_helper"

class Imports::Wordpress::WxrParserTest < ActiveSupport::TestCase
  setup do
    @parser = Imports::Wordpress::WxrParser.new(file_fixture("wordpress.xml").open)
    @items = @parser.items
  end

  test "returns only posts and pages" do
    assert_equal %w[post post post post page page], @items.map(&:post_type)
  end

  test "reads the site url" do
    assert_equal "https://wp.example.com", @parser.site_url
  end

  test "parses post fields" do
    item = @items.find { |i| i.wp_id == "11" }

    assert_equal "Hello & Welcome", item.title
    assert_equal "hello-welcome", item.slug
    assert_equal "publish", item.status
    assert_equal "A short summary of the post.", item.excerpt
    assert_equal Time.utc(2024, 1, 15, 14, 30), item.published_at
    assert_includes item.content, "<strong>paragraph</strong>"
    assert_equal %w[Travel Food], item.categories.map(&:name)
    assert_equal %w[travel food], item.categories.map(&:slug)
    assert_equal %w[Europe], item.tags.map(&:name)
  end

  test "resolves featured image through the attachment item" do
    item = @items.find { |i| i.wp_id == "11" }
    assert_equal "https://wp.example.com/wp-content/uploads/2024/01/hero.jpg", item.featured_image_url
  end

  test "falls back to post_date when post_date_gmt is empty" do
    item = @items.find { |i| i.wp_id == "12" }
    assert_equal Time.utc(2024, 2, 1, 8), item.published_at
    assert_equal "", item.slug
  end

  test "reads page menu order" do
    assert_equal 3, @items.find { |i| i.wp_id == "20" }.menu_order
  end

  test "accepts older WXR namespace versions" do
    xml = file_fixture("wordpress.xml").read.gsub("wordpress.org/export/1.2/", "wordpress.org/export/1.0/")
    items = Imports::Wordpress::WxrParser.parse(StringIO.new(xml))
    assert_equal 6, items.size
  end

  test "raises InvalidFile for non-WordPress XML" do
    assert_raises(Imports::Wordpress::WxrParser::InvalidFile) do
      Imports::Wordpress::WxrParser.new(StringIO.new("<feed><entry/></feed>"))
    end
    assert_raises(Imports::Wordpress::WxrParser::InvalidFile) do
      Imports::Wordpress::WxrParser.new(StringIO.new("<rss><channel/></rss>"))
    end
  end

  test "does not expand external entities" do
    xml = <<~XML
      <?xml version="1.0"?>
      <!DOCTYPE rss [<!ENTITY xxe SYSTEM "file:///etc/passwd">]>
      <rss xmlns:wp="http://wordpress.org/export/1.2/" xmlns:content="http://purl.org/rss/1.0/modules/content/">
        <channel><item><title>&xxe;</title><wp:post_type>post</wp:post_type><wp:status>draft</wp:status></item></channel>
      </rss>
    XML
    item = Imports::Wordpress::WxrParser.parse(StringIO.new(xml)).first
    assert_not_includes item.title.to_s, "root:"
  end
end
