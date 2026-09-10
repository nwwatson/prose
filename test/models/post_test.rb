require "test_helper"

class PostTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

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

  test "publish! enqueues a post.published webhook delivery" do
    post = posts(:draft_post)

    assert_enqueued_with(job: DeliverWebhookJob, args: ->(args) { args[0] == webhooks(:post_events_webhook).id && args[1] == "post.published" }) do
      post.publish!
    end
  end

  test "schedule! enqueues a post.scheduled webhook delivery" do
    post = posts(:draft_post)

    assert_enqueued_jobs 1, only: DeliverWebhookJob do
      post.schedule!(1.day.from_now)
    end
  end

  test "revert_to_draft! enqueues a post.unpublished webhook delivery" do
    post = posts(:published_post)

    assert_enqueued_with(job: DeliverWebhookJob, args: ->(args) { args[0] == webhooks(:post_events_webhook).id && args[1] == "post.unpublished" }) do
      post.revert_to_draft!
    end
  end

  test "updating post content enqueues a post.updated webhook delivery" do
    post = posts(:published_post)

    assert_enqueued_with(job: DeliverWebhookJob, args: ->(args) { args[0] == webhooks(:post_events_webhook).id && args[1] == "post.updated" }) do
      post.update!(title: "Updated Title")
    end
  end

  test "destroying a post enqueues a post.deleted webhook delivery" do
    assert_enqueued_jobs 1, only: DeliverWebhookJob do
      posts(:draft_post).destroy
    end
  end
end
