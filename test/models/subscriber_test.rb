require "test_helper"

class SubscriberTest < ActiveSupport::TestCase
  test "valid subscriber" do
    subscriber = Subscriber.new(email: "new@example.com")
    assert subscriber.valid?
  end

  test "auto-builds identity on create" do
    subscriber = Subscriber.new(email: "new@example.com")
    assert subscriber.valid?
    assert_not_nil subscriber.identity
    assert_equal "new", subscriber.identity.name
  end

  test "handle delegates to identity" do
    subscriber = subscribers(:confirmed)
    assert_equal "subscriber1", subscriber.handle
  end

  test "requires email" do
    subscriber = Subscriber.new
    assert_not subscriber.valid?
  end

  test "requires unique email" do
    subscriber = Subscriber.new(email: "subscriber@example.com")
    assert_not subscriber.valid?
  end

  test "normalizes email" do
    subscriber = Subscriber.new(email: "  TEST@Example.COM  ")
    assert_equal "test@example.com", subscriber.email
  end

  test "confirmed? returns true when confirmed_at is set" do
    assert subscribers(:confirmed).confirmed?
  end

  test "confirmed? returns false when confirmed_at is nil" do
    assert_not subscribers(:unconfirmed).confirmed?
  end

  test "confirm! sets confirmed_at" do
    subscriber = subscribers(:unconfirmed)
    subscriber.confirm!
    assert subscriber.confirmed?
  end

  test "confirmed scope excludes unconfirmed" do
    confirmed = Subscriber.confirmed
    assert_includes confirmed, subscribers(:confirmed)
    assert_not_includes confirmed, subscribers(:unconfirmed)
  end

  test "confirmed scope excludes unsubscribed" do
    subscriber = subscribers(:confirmed)
    subscriber.unsubscribe!
    assert_not_includes Subscriber.confirmed, subscriber
  end

  test "active scope excludes unsubscribed" do
    subscriber = subscribers(:confirmed)
    assert_includes Subscriber.active, subscriber

    subscriber.unsubscribe!
    assert_not_includes Subscriber.active, subscriber
  end

  test "unsubscribe! sets unsubscribed_at" do
    subscriber = subscribers(:confirmed)
    assert_not subscriber.unsubscribed?

    subscriber.unsubscribe!
    assert subscriber.unsubscribed?
    assert_not_nil subscriber.unsubscribed_at
  end

  test "unsubscribe! is idempotent" do
    subscriber = subscribers(:confirmed)
    subscriber.unsubscribe!
    original_time = subscriber.unsubscribed_at

    subscriber.unsubscribe!
    assert_equal original_time.to_i, subscriber.unsubscribed_at.to_i
  end

  test "resubscribe! clears unsubscribed_at" do
    subscriber = subscribers(:confirmed)
    subscriber.unsubscribe!
    assert subscriber.unsubscribed?

    subscriber.resubscribe!
    assert_not subscriber.unsubscribed?
    assert_nil subscriber.unsubscribed_at
  end
end
