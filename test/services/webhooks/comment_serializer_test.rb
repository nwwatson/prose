require "test_helper"

class Webhooks::CommentSerializerTest < ActiveSupport::TestCase
  test "serializes the comment fields" do
    comment = comments(:top_level)

    assert_equal(
      {
        id: comment.id,
        post_id: posts(:published_post).id,
        body: "Great post!",
        approved: true,
        author: "subscriber1",
        created_at: comment.created_at.iso8601
      },
      Webhooks::CommentSerializer.call(comment)
    )
  end

  test "reports pending comments as unapproved" do
    assert_equal false, Webhooks::CommentSerializer.call(comments(:pending_comment))[:approved]
  end

  test "exposes the author's name only, never their email or tokens" do
    comment = comments(:top_level)
    subscriber = subscribers(:confirmed)
    subscriber.generate_auth_token!
    payload = Webhooks::CommentSerializer.call(comment)

    assert_equal %i[id post_id body approved author created_at], payload.keys
    json = payload.to_json
    assert_not_includes json, subscriber.email
    assert_not_includes json, subscriber.reload.auth_token
    assert_no_match(/token|digest|email|password/i, payload.keys.join(" "))
  end
end
