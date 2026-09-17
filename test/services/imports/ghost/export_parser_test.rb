require "test_helper"

class Imports::Ghost::ExportParserTest < ActiveSupport::TestCase
  setup do
    @items = Imports::Ghost::ExportParser.parse(file_fixture("ghost.json").open("rb"))
  end

  test "returns posts and pages" do
    assert_equal %w[post post post post post page page], @items.map(&:post_type)
  end

  test "parses post fields and posts_meta" do
    item = find("ghost-cards")

    assert_equal "Ghost Cards", item.title
    assert_equal "published", item.status
    assert_equal "paid", item.visibility
    assert item.featured
    assert_equal "A tour of every card", item.custom_excerpt
    assert_equal "Meta from posts_meta", item.meta_description
    assert_equal Time.utc(2024, 1, 10, 12), item.published_at
    assert_equal "__GHOST_URL__/content/images/2024/01/feature.jpg", item.feature_image
    assert_equal :html, item.content_source
    assert_includes item.content, "💡"
  end

  test "orders tags by sort_order and drops internal tags" do
    assert_equal %w[Guides Ghost], find("ghost-cards").tags.map(&:name)
    assert_equal %w[Ghost], find("mobiledoc-only").tags.map(&:name)
  end

  test "renders mobiledoc when html is missing" do
    item = find("mobiledoc-only")

    assert_equal :mobiledoc, item.content_source
    assert_includes item.content, "<h2>Mobiledoc heading</h2>"
  end

  test "falls back to escaped plaintext paragraphs" do
    item = find("lexical-only")

    assert_equal :plaintext, item.content_source
    assert_equal "<p>First line.</p>\n<p>Second &lt;line&gt;.</p>", item.content
  end

  test "accepts exports without the db wrapper" do
    data = JSON.parse(file_fixture("ghost.json").read(encoding: "UTF-8"))["db"].first
    items = Imports::Ghost::ExportParser.parse(StringIO.new(JSON.generate(data)))

    assert_equal 7, items.size
  end

  test "raises InvalidFile for invalid or non-Ghost JSON" do
    [ "not json", "[]", '{"db":[{"data":{}}]}', '{"posts":[]}' ].each do |body|
      assert_raises(Imports::Ghost::ExportParser::InvalidFile, body) do
        Imports::Ghost::ExportParser.parse(StringIO.new(body))
      end
    end
  end

  private

  def find(slug)
    @items.find { |item| item.slug == slug }
  end
end
