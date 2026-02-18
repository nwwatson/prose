require "test_helper"

class LoveTest < ActiveSupport::TestCase
  test "valid love" do
    love = Love.new(post: posts(:draft_post), identity: identities(:subscriber_identity))
    assert love.valid?
  end

  test "unique constraint on post and identity" do
    love = Love.new(post: posts(:published_post), identity: identities(:subscriber_identity))
    assert_not love.valid?
    assert love.errors[:identity_id].any?
  end
end
