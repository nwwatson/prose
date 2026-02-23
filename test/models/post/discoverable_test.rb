require "test_helper"

class Post::DiscoverableTest < ActiveSupport::TestCase
  # Fixtures:
  # published_post: published 1 day ago, category: technology, tags: [ruby, rails]
  # featured_post: published 2 hours ago, category: technology, tags: [ruby]
  # related_ruby_post: published 3 days ago, category: technology, tags: [ruby, rails]
  # related_rails_post: published 5 days ago, category: technology, tags: [rails]
  # design_post: published 4 days ago, category: design, tags: [css]
  # draft_post: draft, no category, no tags
  # scheduled_post: scheduled for future, no category, no tags

  test "related_posts returns posts with most shared tags first" do
    post = posts(:published_post) # tags: ruby, rails
    related = post.related_posts

    # related_ruby_post shares 2 tags (ruby, rails) — should rank first
    assert_equal posts(:related_ruby_post), related.first
  end

  test "related_posts excludes the current post" do
    post = posts(:published_post)
    related = post.related_posts

    refute_includes related, post
  end

  test "related_posts excludes unpublished posts" do
    post = posts(:published_post)
    related = post.related_posts

    refute_includes related, posts(:draft_post)
    refute_includes related, posts(:scheduled_post)
  end

  test "related_posts returns up to limit posts" do
    post = posts(:published_post)
    related = post.related_posts(limit: 2)

    assert_equal 2, related.size
  end

  test "related_posts backfills with category matches when insufficient tag matches" do
    post = posts(:design_post) # category: design, tags: [javascript]
    # No other posts share the css tag, so it should backfill
    related = post.related_posts(limit: 3)

    assert_equal 3, related.size
  end

  test "related_posts backfills with recent posts as last resort" do
    post = posts(:design_post) # category: design — only design post
    related = post.related_posts(limit: 3)

    # No other posts share tags or category, so all 3 are recent backfills
    assert_equal 3, related.size
    related.each do |rp|
      refute_equal post, rp
    end
  end

  test "related_posts returns empty array when no other published posts exist" do
    # Delete all posts except one
    Post.where.not(id: posts(:published_post).id).destroy_all
    related = posts(:published_post).related_posts

    assert_empty related
  end

  test "previous_post returns the most recent post published before this one" do
    post = posts(:published_post) # published 1 day ago
    previous = post.previous_post

    # related_ruby_post (3 days ago) is the next most recent before published_post
    assert_equal posts(:related_ruby_post), previous
  end

  test "next_post returns the earliest post published after this one" do
    post = posts(:published_post) # published 1 day ago
    next_p = post.next_post

    # featured_post (2 hours ago) is the next post after published_post
    assert_equal posts(:featured_post), next_p
  end

  test "previous_post returns nil for the oldest published post" do
    post = posts(:related_rails_post) # published 5 days ago — oldest
    assert_nil post.previous_post
  end

  test "next_post returns nil for the newest published post" do
    post = posts(:featured_post) # published 2 hours ago — newest
    assert_nil post.next_post
  end

  test "previous_post and next_post exclude unpublished posts" do
    post = posts(:featured_post) # newest published
    assert_nil post.next_post # scheduled_post is in future but not published
  end

  test "related_posts for a post with no tags falls back to category" do
    # Create a post with no tags but a category
    post = Post.create!(title: "No Tags Post", user: users(:admin), category: categories(:technology),
                        status: :published, published_at: 6.days.ago)

    related = post.related_posts(limit: 3)
    assert related.size > 0
    assert related.all? { |rp| rp.id != post.id }
  end
end
