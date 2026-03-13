require "test_helper"

class Post::AccessibleTest < ActiveSupport::TestCase
  setup do
    @post = posts(:published_post)
    @subscriber = subscribers(:confirmed)
  end

  test "public posts are accessible by anyone" do
    @post.update!(visibility: :public)
    assert @post.accessible_by?(nil)
    assert @post.accessible_by?(@subscriber)
  end

  test "members_only posts require confirmed subscriber" do
    @post.update!(visibility: :members_only)
    assert_not @post.accessible_by?(nil)
    assert @post.accessible_by?(@subscriber)
  end

  test "members_only posts deny unconfirmed subscribers" do
    @post.update!(visibility: :members_only)
    assert_not @post.accessible_by?(subscribers(:unconfirmed))
  end

  test "paid_only posts require paid membership" do
    @post.update!(visibility: :paid_only)
    assert_not @post.accessible_by?(nil)
    # confirmed subscriber has an active membership via fixtures
    assert @post.accessible_by?(@subscriber)
  end

  test "paid_only posts deny free members" do
    @post.update!(visibility: :paid_only)
    assert_not @post.accessible_by?(subscribers(:unconfirmed))
  end

  test "requires_membership?" do
    @post.update!(visibility: :public)
    assert_not @post.requires_membership?

    @post.update!(visibility: :members_only)
    assert @post.requires_membership?
  end

  test "requires_paid_membership?" do
    @post.update!(visibility: :public)
    assert_not @post.requires_paid_membership?

    @post.update!(visibility: :paid_only)
    assert @post.requires_paid_membership?
  end
end
