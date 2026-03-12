require "test_helper"

class CommentTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper
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

  # Editable concern
  test "editable_by? returns true for author within edit window" do
    comment = comments(:recent_comment)
    assert comment.editable_by?(identities(:subscriber_identity))
  end

  test "editable_by? returns false for different identity" do
    comment = comments(:recent_comment)
    assert_not comment.editable_by?(identities(:from_published_post_identity))
  end

  test "editable_by? returns false outside edit window" do
    comment = comments(:top_level)
    assert_not comment.editable_by?(identities(:subscriber_identity))
  end

  test "editable_by? returns false for deleted comment" do
    comment = comments(:deleted_comment)
    assert_not comment.editable_by?(identities(:subscriber_identity))
  end

  test "deletable_by? returns true for author" do
    comment = comments(:top_level)
    assert comment.deletable_by?(identities(:subscriber_identity))
  end

  test "deletable_by? returns false for different identity" do
    comment = comments(:top_level)
    assert_not comment.deletable_by?(identities(:from_published_post_identity))
  end

  test "deletable_by? returns false for already deleted comment" do
    comment = comments(:deleted_comment)
    assert_not comment.deletable_by?(identities(:subscriber_identity))
  end

  test "soft_delete! sets deleted_at and replaces body" do
    comment = comments(:recent_comment)
    comment.soft_delete!
    assert comment.deleted?
    assert_equal "[deleted]", comment.body
    assert_not_nil comment.deleted_at
  end

  test "deleted? returns true when deleted_at present" do
    assert comments(:deleted_comment).deleted?
  end

  test "deleted? returns false when deleted_at nil" do
    assert_not comments(:top_level).deleted?
  end

  test "edited? returns true when edited_at present" do
    comment = comments(:recent_comment)
    comment.update!(edited_at: Time.current)
    assert comment.edited?
  end

  test "edited? returns false when edited_at nil" do
    assert_not comments(:top_level).edited?
  end

  test "visible scope excludes deleted comments" do
    visible = Comment.visible
    assert_includes visible, comments(:top_level)
    assert_not_includes visible, comments(:deleted_comment)
  end

  # Notifiable concern
  test "creating reply enqueues notification job when parent has notify_on_reply" do
    assert_enqueued_with(job: CommentReplyNotificationJob) do
      Comment.create!(
        post: posts(:published_post),
        identity: identities(:from_published_post_identity),
        parent_comment: comments(:top_level),
        body: "New reply!"
      )
    end
  end

  test "creating reply does not enqueue job when parent has notify_on_reply false" do
    comments(:top_level).update!(notify_on_reply: false)
    assert_no_enqueued_jobs(only: CommentReplyNotificationJob) do
      Comment.create!(
        post: posts(:published_post),
        identity: identities(:from_published_post_identity),
        parent_comment: comments(:top_level),
        body: "New reply!"
      )
    end
  end

  test "creating reply does not enqueue job when replying to own comment" do
    assert_no_enqueued_jobs(only: CommentReplyNotificationJob) do
      Comment.create!(
        post: posts(:published_post),
        identity: identities(:subscriber_identity),
        parent_comment: comments(:top_level),
        body: "Self reply"
      )
    end
  end

  test "creating top-level comment does not enqueue notification job" do
    assert_no_enqueued_jobs(only: CommentReplyNotificationJob) do
      Comment.create!(
        post: posts(:published_post),
        identity: identities(:subscriber_identity),
        body: "Top level"
      )
    end
  end
end
