require "test_helper"

module ActivityPub
  class ArticleSerializerTest < ActiveSupport::TestCase
    setup do
      @post = posts(:published_post)
    end

    test "serializes a public post as an Article with its full content" do
      @post.update!(content: %(<p>Hello <a href="/about">about</a></p>))
      article = ArticleSerializer.call(@post)

      assert_equal "Article", article["type"]
      assert_equal Urls.post_url(@post), article["id"]
      assert_equal Urls.actor_url, article["attributedTo"]
      assert_equal @post.title, article["name"]
      assert_includes article["to"], Urls::PUBLIC_COLLECTION
      assert_includes article["content"], "Hello"
      assert_includes article["content"], %(href="#{Urls.base_url}/about")
    end

    test "gated posts federate only a teaser and a link" do
      @post.update!(content: "<p>#{"Intro. " * 50}Secret paid content</p>", visibility: :paid_only, meta_description: "A teaser")
      article = ArticleSerializer.call(@post)

      assert_not_includes article["content"], "Secret paid content"
      assert_includes article["content"], "A teaser"
      assert_includes article["content"], %(href="#{Urls.post_url(@post)}")
    end

    test "includes post tags as hashtags" do
      tag = @post.tags.first || tags(:ruby).tap { |t| @post.tags << t }
      hashtag = ArticleSerializer.call(@post)["tag"].find { |t| t["href"] == Urls.tag_url(tag) }
      assert_equal "Hashtag", hashtag["type"]
    end

    test "Create and Update activities wrap the article with unique ids" do
      create = Activities.create(@post)
      update = Activities.update(@post)

      assert_equal "Create", create["type"]
      assert_equal "Update", update["type"]
      assert_not_equal create["id"], update["id"]
      assert_equal Urls.post_url(@post), create.dig("object", "id")
      assert_nil create["object"]["@context"]
    end

    test "Delete sends a Tombstone" do
      delete = Activities.delete("https://example.com/posts/gone")
      assert_equal({ "id" => "https://example.com/posts/gone", "type" => "Tombstone" }, delete["object"])
    end
  end
end
