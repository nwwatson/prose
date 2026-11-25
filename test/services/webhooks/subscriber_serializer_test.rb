require "test_helper"

class Webhooks::SubscriberSerializerTest < ActiveSupport::TestCase
  test "serializes the public subscriber fields" do
    subscriber = subscribers(:confirmed)

    assert_equal(
      {
        id: subscriber.id,
        email: "subscriber@example.com",
        confirmed: true,
        created_at: subscriber.created_at.iso8601
      },
      Webhooks::SubscriberSerializer.call(subscriber)
    )
  end

  test "reports unconfirmed subscribers" do
    assert_equal false, Webhooks::SubscriberSerializer.call(subscribers(:unconfirmed))[:confirmed]
  end

  test "never includes auth tokens or other secrets" do
    subscriber = subscribers(:with_token)
    payload = Webhooks::SubscriberSerializer.call(subscriber)

    assert_equal %i[id email confirmed created_at], payload.keys
    json = payload.to_json
    assert_not_includes json, subscriber.auth_token
    assert_no_match(/token|digest|password|stripe/i, payload.keys.join(" "))
  end
end
