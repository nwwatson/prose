require "test_helper"

class CommentTest < ActiveSupport::TestCase
  test "valid comment" do
    comment = Comment.new(post: posts(:published_post), identity: identities(:subscriber_identity), body: "Nice!")
    assert comment.valid?
  end

  test "requires body" do
    comment = Comment.new(post: posts(:published_post), identity: identities(:subscriber_identity))
    assert_not comment.valid?
    assert_includes comment.errors[:body], "can't be blank"
  end

  test "allows one level of nesting" do
    comment = Comment.new(post: posts(:published_post), identity: identities(:subscriber_identity), body: "Reply", parent_comment: comments(:top_level))
    assert comment.valid?
  end

  test "prevents two levels of nesting" do
    comment = Comment.new(post: posts(:published_post), identity: identities(:subscriber_identity), body: "Deep reply", parent_comment: comments(:reply))
    assert_not comment.valid?
    assert comment.errors[:parent_comment].any?
  end

  test "approved scope" do
    approved = Comment.approved
    assert_includes approved, comments(:top_level)
    assert_not_includes approved, comments(:pending_comment)
  end

  test "top_level scope" do
    top = Comment.top_level
    assert_includes top, comments(:top_level)
    assert_not_includes top, comments(:reply)
  end

  test "pending_moderation scope" do
    pending = Comment.pending_moderation
    assert_includes pending, comments(:pending_comment)
    assert_not_includes pending, comments(:top_level)
  end
end
