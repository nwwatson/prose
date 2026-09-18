require "test_helper"

class Subscriber::EmailPreferencesTest < ActiveSupport::TestCase
  setup do
    @subscriber = subscribers(:confirmed)
  end

  test "defaults to immediate" do
    subscriber = Subscriber.create!(email: "new-reader@example.com")

    assert subscriber.email_immediate?
    assert_not subscriber.email_digest?
  end

  test "rejects an unknown frequency" do
    @subscriber.email_frequency = "hourly"

    assert_not @subscriber.valid?
    assert @subscriber.errors[:email_frequency].any?
  end

  test "email_digest? is true only for weekly and monthly" do
    assert Subscriber.new(email_frequency: :weekly).email_digest?
    assert Subscriber.new(email_frequency: :monthly).email_digest?
    assert_not Subscriber.new(email_frequency: :immediate).email_digest?
    assert_not Subscriber.new(email_frequency: :none).email_digest?
  end

  test "switching from immediate to a digest starts the window now" do
    freeze_time do
      @subscriber.update!(email_frequency: :weekly)

      assert_equal Time.current, @subscriber.last_digest_at
      assert_equal Time.current, @subscriber.digest_window_start
    end
  end

  test "switching between digest frequencies keeps the cursor" do
    cursor = 3.weeks.ago.change(usec: 0)
    @subscriber.update!(email_frequency: :monthly)
    @subscriber.update_column(:last_digest_at, cursor)

    @subscriber.update!(email_frequency: :weekly)

    assert_equal cursor, @subscriber.reload.last_digest_at
  end

  test "switching from none to a digest covers the most recent period" do
    @subscriber.update!(email_frequency: :none)
    @subscriber.update!(email_frequency: :monthly)

    assert_nil @subscriber.last_digest_at
    freeze_time do
      assert_equal 1.month.ago, @subscriber.digest_window_start
    end
  end

  test "saving without changing the frequency leaves the cursor alone" do
    @subscriber.update!(email_frequency: :weekly)
    cursor = @subscriber.last_digest_at

    travel 1.day do
      @subscriber.update!(confirmed_at: Time.current)
    end

    assert_equal cursor, @subscriber.reload.last_digest_at
  end

  test "digest_window_start falls back to one period ago without a cursor" do
    freeze_time do
      @subscriber.email_frequency = :weekly
      assert_equal 1.week.ago, @subscriber.digest_window_start

      @subscriber.email_frequency = :monthly
      assert_equal 1.month.ago, @subscriber.digest_window_start
    end
  end

  test "email preferences token round-trips to the subscriber" do
    token = @subscriber.email_preferences_token

    assert_equal @subscriber, Subscriber.find_by_email_preferences_token(token)
  end

  test "find_by_email_preferences_token rejects tampered, foreign and expired tokens" do
    unsubscribe_token = Rails.application.message_verifier("unsubscribe").generate(@subscriber.id)

    assert_nil Subscriber.find_by_email_preferences_token("garbage")
    assert_nil Subscriber.find_by_email_preferences_token(unsubscribe_token)

    token = @subscriber.email_preferences_token
    travel 31.days do
      assert_nil Subscriber.find_by_email_preferences_token(token)
    end
  end
end
