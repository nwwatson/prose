require "test_helper"

class SubscriberTest < ActiveSupport::TestCase
  include ActionMailer::TestHelper
  include ActiveJob::TestHelper

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

  test "subscribe_or_sign_in! creates a new subscriber and delivers a confirmation email" do
    assert_difference "Subscriber.count", 1 do
      assert_enqueued_emails 1 do
        Subscriber.subscribe_or_sign_in!(email: "brandnew@example.com")
      end
    end

    subscriber = Subscriber.find_by(email: "brandnew@example.com")
    assert_not_nil subscriber.auth_token
  end

  test "subscribe_or_sign_in! sets source_post_id for a new subscriber" do
    published_post = posts(:published_post)
    subscriber = Subscriber.subscribe_or_sign_in!(email: "withpost@example.com", source_post_id: published_post.id)
    assert_equal published_post.id, subscriber.source_post_id
  end

  test "subscribe_or_sign_in! sends a magic link and does not duplicate an existing subscriber" do
    existing = subscribers(:confirmed)

    assert_no_difference "Subscriber.count" do
      assert_enqueued_emails 1 do
        Subscriber.subscribe_or_sign_in!(email: existing.email)
      end
    end

    assert_not_nil existing.reload.auth_token
  end

  test "subscribe_or_sign_in! does not overwrite source_post_id for an existing subscriber" do
    existing = subscribers(:from_published_post)
    original_source = existing.source_post_id

    Subscriber.subscribe_or_sign_in!(email: existing.email, source_post_id: posts(:featured_post).id)

    assert_equal original_source, existing.reload.source_post_id
  end

  test "subscribe_or_sign_in! enqueues a subscriber.created webhook delivery for a new subscriber" do
    assert_enqueued_jobs 1, only: DeliverWebhookJob do
      Subscriber.subscribe_or_sign_in!(email: "brand-new@example.com")
    end
  end

  test "subscribe_or_sign_in! does not enqueue a webhook delivery for an existing subscriber" do
    existing = subscribers(:confirmed)

    assert_no_enqueued_jobs only: DeliverWebhookJob do
      Subscriber.subscribe_or_sign_in!(email: existing.email)
    end
  end

  test "unsubscribe! enqueues a subscriber.deleted webhook delivery" do
    subscriber = subscribers(:confirmed)

    assert_enqueued_jobs 1, only: DeliverWebhookJob do
      subscriber.unsubscribe!
    end
  end

  test "unsubscribe! does not enqueue a webhook delivery when already unsubscribed" do
    subscriber = subscribers(:confirmed)
    subscriber.unsubscribe!

    assert_no_enqueued_jobs only: DeliverWebhookJob do
      subscriber.unsubscribe!
    end
  end
end
