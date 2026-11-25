require "test_helper"

# Destroying a parent removes its callback-free children, which are deleted with
# one statement per table (dependent: :delete_all) rather than row by row.
class DependentCleanupTest < ActiveSupport::TestCase
  setup do
    @post = Post.create!(title: "Cleanup", user: users(:admin))
    @identity = Identity.create!(name: "Cleanup Reader")
    @actor = FediverseActor.create!(uri: "https://remote.example/users/cleanup", inbox_url: "https://remote.example/inbox")
    @subscriber = Subscriber.create!(email: "cleanup@example.com")
  end

  test "destroying a post removes its children with one DELETE per table" do
    tags = [ tags(:ruby), Tag.create!(name: "Cleanup") ]
    tags.each { |tag| @post.post_tags.create!(tag: tag) }
    2.times do |i|
      @post.post_views.create!(ip_hash: "hash#{i}")
      @post.create_version!(user: users(:admin))
    end
    ReadingListItem.create!(identity: @identity, post: @post)
    ReadingListItem.create!(identity: identities(:admin_identity), post: @post)
    FediverseLike.create!(post: @post, fediverse_actor: @actor)
    FediverseLike.create!(post: @post, fediverse_actor: FediverseActor.create!(uri: "https://remote.example/users/other"))

    deletes = capture_deletes { Post.find(@post.id).destroy! }

    %w[post_tags post_views post_versions reading_list_items fediverse_likes].each do |table|
      assert_equal 1, deletes[table], "expected one DELETE against #{table}"
      assert_equal 0, table.classify.constantize.where(post_id: @post.id).count
    end
  end

  test "destroying a tag removes its post tags" do
    tag = Tag.create!(name: "Cleanup")
    @post.post_tags.create!(tag: tag)

    assert_difference -> { PostTag.count }, -1 do
      tag.destroy!
    end
  end

  test "destroying a fediverse actor removes its likes" do
    FediverseLike.create!(post: @post, fediverse_actor: @actor)

    assert_difference -> { FediverseLike.count }, -1 do
      @actor.destroy!
    end
  end

  test "destroying an identity removes its reading list" do
    ReadingListItem.create!(identity: @identity, post: @post)

    assert_difference -> { ReadingListItem.count }, -1 do
      @identity.destroy!
    end
  end

  test "destroying a newsletter removes its deliveries" do
    newsletter = Newsletter.create!(title: "Cleanup", user: users(:admin))
    NewsletterDelivery.create!(newsletter: newsletter, subscriber: @subscriber)

    assert_difference -> { NewsletterDelivery.count }, -1 do
      newsletter.destroy!
    end
  end

  test "destroying a subscriber removes its deliveries and labelings" do
    NewsletterDelivery.create!(newsletter: newsletters(:draft_newsletter), subscriber: @subscriber)
    SubscriberLabeling.create!(subscriber: @subscriber, subscriber_label: subscriber_labels(:vip))

    assert_difference [ -> { NewsletterDelivery.count }, -> { SubscriberLabeling.count } ], -1 do
      @subscriber.destroy!
    end
  end

  test "destroying a subscriber label removes its labelings" do
    label = SubscriberLabel.create!(name: "Cleanup", color: "#000000")
    SubscriberLabeling.create!(subscriber: @subscriber, subscriber_label: label)

    assert_difference -> { SubscriberLabeling.count }, -1 do
      label.destroy!
    end
  end

  test "destroying a webhook removes its delivery log" do
    webhook = webhooks(:post_events_webhook)
    webhook.webhook_deliveries.create!(event: "ping", attempted_at: Time.current)

    webhook.destroy!

    assert_equal 0, WebhookDelivery.where(webhook_id: webhook.id).count
  end

  private

  def capture_deletes
    deletes = Hash.new(0)
    counter = ->(*, payload) do
      table = payload[:sql][/\ADELETE FROM "(\w+)"/, 1]
      deletes[table] += 1 if table
    end
    ActiveSupport::Notifications.subscribed(counter, "sql.active_record") { yield }
    deletes
  end
end
