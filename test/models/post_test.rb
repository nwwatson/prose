require "test_helper"

class PostTest < ActiveSupport::TestCase
  test "valid post" do
    post = Post.new(title: "Test Post", user: users(:admin))
    assert post.valid?
  end

  test "requires title" do
    post = Post.new(user: users(:admin))
    assert_not post.valid?
    assert_includes post.errors[:title], "can't be blank"
  end

  test "defaults to draft status" do
    post = Post.new
    assert post.draft?
  end

  test "featured scope" do
    featured = Post.featured
    assert_includes featured, posts(:featured_post)
    assert_not_includes featured, posts(:published_post)
  end

  test "by_publication_date scope orders by published_at descending" do
    posts = Post.published.by_publication_date
    assert_equal posts(:featured_post), posts.first
  end

  test "seo_description prefers meta_description" do
    post = posts(:published_post)
    post.meta_description = "Custom meta description"
    assert_equal "Custom meta description", post.seo_description
  end

  test "seo_description falls back to subtitle" do
    post = posts(:published_post)
    post.meta_description = nil
    assert_equal post.subtitle, post.seo_description
  end

  test "seo_description falls back to excerpt of body_plain" do
    post = posts(:published_post)
    post.meta_description = nil
    post.subtitle = nil
    assert_equal post.excerpt(155), post.seo_description
  end

  test "excerpt truncates body_plain to the given length" do
    post = Post.new(body_plain: "word " * 100)
    assert_equal post.body_plain.truncate(50), post.excerpt(50)
  end

  test "excerpt defaults to 300 characters" do
    post = Post.new(body_plain: "word " * 100)
    assert_equal post.body_plain.truncate(300), post.excerpt
  end

  test "with_author preloads user and identity" do
    post = Post.with_author.find(posts(:published_post).id)
    assert_query_count(0, table: "identities") { post.user.identity }
  end

  test "for_listing preloads user, identity, and category" do
    post = Post.for_listing.find(posts(:published_post).id)
    assert_query_count(0, table: "identities") { post.user.identity }
    assert_query_count(0, table: "categories") { post.category }
  end
end
