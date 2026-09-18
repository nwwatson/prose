require "test_helper"

class EmailPreferencesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @subscriber = subscribers(:confirmed)
    @token = @subscriber.email_preferences_token
  end

  test "GET show renders the frequency options with a valid token" do
    get email_preferences_path(token: @token)

    assert_response :success
    assert_match @subscriber.email, response.body
    assert_select "input[type=radio][name='subscriber[email_frequency]']", 4
    assert_select "input[type=radio][value=immediate][checked]"
    assert_select "input[type=hidden][name=token][value=?]", @token
  end

  test "GET show redirects with an invalid token" do
    get email_preferences_path(token: "invalid-token")

    assert_redirected_to root_path
    assert_equal "Invalid or expired email preferences link.", flash[:alert]
  end

  test "GET show redirects without a token when not signed in" do
    get email_preferences_path

    assert_redirected_to root_path
  end

  test "GET show works for a signed-in subscriber without a token" do
    sign_in_subscriber(@subscriber)

    get email_preferences_path

    assert_response :success
    assert_match @subscriber.email, response.body
    assert_select "input[type=hidden][name=token]", 0
  end

  test "GET show notes when the subscriber is unsubscribed" do
    @subscriber.update!(unsubscribed_at: Time.current)

    get email_preferences_path(token: @token)

    assert_response :success
    assert_match "unsubscribed", response.body
  end

  test "PATCH update changes the frequency" do
    patch email_preferences_path, params: { token: @token, subscriber: { email_frequency: "weekly" } }

    assert_redirected_to email_preferences_path(token: @token)
    assert @subscriber.reload.email_weekly?
    assert_equal "Your email preferences have been saved.", flash[:notice]
  end

  test "PATCH update works for a signed-in subscriber" do
    sign_in_subscriber(@subscriber)

    patch email_preferences_path, params: { subscriber: { email_frequency: "monthly" } }

    assert_redirected_to email_preferences_path
    assert @subscriber.reload.email_monthly?
  end

  test "PATCH update rejects an unknown frequency" do
    patch email_preferences_path, params: { token: @token, subscriber: { email_frequency: "hourly" } }

    assert_response :unprocessable_entity
    assert @subscriber.reload.email_immediate?
  end

  test "PATCH update with an invalid token changes nothing" do
    patch email_preferences_path, params: { token: "invalid-token", subscriber: { email_frequency: "none" } }

    assert_redirected_to root_path
    assert @subscriber.reload.email_immediate?
  end

  test "PATCH update does not resubscribe an unsubscribed subscriber" do
    @subscriber.update!(unsubscribed_at: Time.current)

    patch email_preferences_path, params: { token: @token, subscriber: { email_frequency: "weekly" } }

    assert @subscriber.reload.unsubscribed?
  end
end

class EmailPreferencesMailingListsTest < ActionDispatch::IntegrationTest
  setup do
    @subscriber = subscribers(:confirmed)
    @token = @subscriber.email_preferences_token
  end

  test "GET show lists active mailing lists with the subscriber's checked" do
    get email_preferences_path(token: @token)

    assert_select "input[type=checkbox][name='subscriber[selected_mailing_list_ids][]'][checked]", 2
    assert_select "input[type=checkbox][value=?]", mailing_lists(:retired).id.to_s, count: 0
    assert_match "Deep Dives", response.body
  end

  test "GET show hides the list choice when only one list is active" do
    mailing_lists(:deep_dives).update!(active: false)

    get email_preferences_path(token: @token)

    assert_select "input[type=checkbox][name='subscriber[selected_mailing_list_ids][]']", 0
  end

  test "PATCH update changes list subscriptions" do
    patch email_preferences_path, params: {
      token: @token,
      subscriber: { email_frequency: "immediate", selected_mailing_list_ids: [ "", mailing_lists(:deep_dives).id ] }
    }

    assert_redirected_to email_preferences_path(token: @token)
    assert_equal [ mailing_lists(:deep_dives), mailing_lists(:retired) ].sort_by(&:id), @subscriber.mailing_lists.reload.sort_by(&:id)
  end

  test "PATCH update without list params keeps subscriptions" do
    patch email_preferences_path, params: { token: @token, subscriber: { email_frequency: "weekly" } }

    assert_equal 3, @subscriber.mailing_lists.reload.count
    assert @subscriber.reload.email_weekly?
  end
end
