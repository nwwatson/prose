require "test_helper"

class CommentsControllerTest < ActionDispatch::IntegrationTest
  test "POST create requires identity" do
    post post_comments_path(posts(:published_post)), params: { comment: { body: "Test" } }
    assert_redirected_to root_path
  end

  test "POST create creates comment as subscriber" do
    sign_in_subscriber(subscribers(:confirmed))

    assert_difference "Comment.count", 1 do
      post post_comments_path(posts(:published_post)), params: { comment: { body: "Great article!" } }
    end
  end

  test "POST create creates comment as staff user" do
    sign_in_as(:admin)

    assert_difference "Comment.count", 1 do
      post post_comments_path(posts(:published_post)), params: { comment: { body: "Staff comment!" } }
    end
  end

  test "POST create with notify_on_reply sets the flag" do
    sign_in_subscriber(subscribers(:confirmed))

    post post_comments_path(posts(:published_post)), params: { comment: { body: "Notify me!", notify_on_reply: "1" } }
    assert Comment.last.notify_on_reply?
  end

  test "PATCH update edits comment within edit window" do
    sign_in_subscriber(subscribers(:confirmed))
    comment = comments(:recent_comment)

    patch post_comment_path(posts(:published_post), comment), params: { comment: { body: "Updated body" } }
    comment.reload
    assert_equal "Updated body", comment.body
    assert_not_nil comment.edited_at
  end

  test "PATCH update rejects edit outside edit window" do
    sign_in_subscriber(subscribers(:confirmed))
    comment = comments(:top_level)

    patch post_comment_path(posts(:published_post), comment), params: { comment: { body: "Should fail" } }
    assert_redirected_to post_path(posts(:published_post), slug: posts(:published_post).slug)
    comment.reload
    assert_equal "Great post!", comment.body
  end

  test "PATCH update rejects edit by non-author" do
    sign_in_subscriber(subscribers(:from_published_post))
    comment = comments(:recent_comment)

    patch post_comment_path(posts(:published_post), comment), params: { comment: { body: "Not my comment" } }
    assert_redirected_to post_path(posts(:published_post), slug: posts(:published_post).slug)
    comment.reload
    assert_equal "A recent comment within edit window", comment.body
  end

  test "DELETE destroy soft-deletes comment by author" do
    sign_in_subscriber(subscribers(:confirmed))
    comment = comments(:recent_comment)

    delete post_comment_path(posts(:published_post), comment)
    comment.reload
    assert comment.deleted?
    assert_equal "[deleted]", comment.body
  end

  test "DELETE destroy rejects non-author" do
    sign_in_subscriber(subscribers(:from_published_post))
    comment = comments(:recent_comment)

    delete post_comment_path(posts(:published_post), comment)
    assert_redirected_to post_path(posts(:published_post), slug: posts(:published_post).slug)
    comment.reload
    assert_not comment.deleted?
  end

  test "DELETE destroy requires identity" do
    delete post_comment_path(posts(:published_post), comments(:recent_comment))
    assert_redirected_to root_path
  end
end
