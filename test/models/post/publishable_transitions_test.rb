require "test_helper"

class Post::PublishableTransitionsTest < ActiveSupport::TestCase
  def predicates(post)
    {
      became_published: post.became_published?,
      became_scheduled: post.became_scheduled?,
      left_published: post.left_published?,
      edited_while_published: post.edited_while_published?
    }.select { |_, value| value }.keys
  end

  test "creating a post as published" do
    post = Post.create!(title: "Born published", user: users(:admin), status: :published, published_at: Time.current)
    assert_equal [ :became_published ], predicates(post)
  end

  test "creating a draft is no transition" do
    post = Post.create!(title: "Draft", user: users(:admin))
    assert_empty predicates(post)
  end

  test "draft to published" do
    post = posts(:draft_post)
    post.publish!
    assert_equal [ :became_published ], predicates(post)
  end

  test "published to draft" do
    post = posts(:published_post)
    post.revert_to_draft!
    assert_equal [ :left_published ], predicates(post)
  end

  test "published to scheduled" do
    post = posts(:published_post)
    post.schedule!(1.day.from_now)
    assert_equal [ :became_scheduled, :left_published ], predicates(post)
  end

  test "editing a published post" do
    post = posts(:published_post)
    post.update!(title: "Edited")
    assert_equal [ :edited_while_published ], predicates(post)
  end

  test "a settings-only save of a published post is not an edit" do
    post = posts(:published_post)
    post.update!(content: "<p>Body</p>")
    post.update!(featured: true)
    assert_empty predicates(post)
  end
end
