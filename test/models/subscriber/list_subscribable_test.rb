require "test_helper"

class Subscriber::ListSubscribableTest < ActiveSupport::TestCase
  test "new subscribers join the active default lists only" do
    subscriber = Subscriber.create!(email: "lists@example.com")

    assert_equal [ mailing_lists(:main) ], subscriber.mailing_lists.to_a
  end

  test "selected_mailing_list_ids reads the subscriber's active lists" do
    ids = subscribers(:confirmed).selected_mailing_list_ids

    assert_equal [ mailing_lists(:main).id, mailing_lists(:deep_dives).id ].sort, ids.sort
    assert_not_includes ids, mailing_lists(:retired).id
  end

  test "saving a selection replaces active-list subscriptions" do
    subscriber = subscribers(:confirmed)

    subscriber.update!(selected_mailing_list_ids: [ "", mailing_lists(:deep_dives).id.to_s ])

    assert_equal [ mailing_lists(:deep_dives), mailing_lists(:retired) ].sort_by(&:id), subscriber.mailing_lists.reload.sort_by(&:id)
  end

  test "an empty selection leaves only inactive-list subscriptions" do
    subscriber = subscribers(:confirmed)

    subscriber.update!(selected_mailing_list_ids: [ "" ])

    assert_equal [ mailing_lists(:retired) ], subscriber.mailing_lists.reload.to_a
  end

  test "a selection can't subscribe to an inactive list" do
    subscriber = subscribers(:unconfirmed)

    subscriber.update!(selected_mailing_list_ids: [ mailing_lists(:retired).id, mailing_lists(:deep_dives).id ])

    assert_equal [ mailing_lists(:deep_dives) ], subscriber.mailing_lists.reload.to_a
  end

  test "subscribed_to scopes subscribers to any of the given lists" do
    scope = Subscriber.subscribed_to(MailingList.where(id: mailing_lists(:deep_dives).id))

    assert_equal [ subscribers(:confirmed) ], scope.to_a
  end
end
