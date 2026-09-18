require "test_helper"

class MailingListTest < ActiveSupport::TestCase
  test "requires a unique name" do
    list = MailingList.new(name: "newsletter")

    assert_not list.valid?
    assert list.errors.of_kind?(:name, :taken)
    assert_not MailingList.new(name: "").valid?
  end

  test "generates a slug from the name" do
    list = MailingList.create!(name: "Weekly Links")

    assert_equal "weekly-links", list.slug
  end

  test "subscribed_by_default excludes inactive lists" do
    mailing_lists(:retired).update!(subscribe_by_default: true)

    assert_equal [ mailing_lists(:main) ], MailingList.subscribed_by_default.to_a
  end

  test "recipients are confirmed, still-subscribed members of the list" do
    list = mailing_lists(:main)
    subscribers(:with_token).unsubscribe!

    recipients = list.recipients

    assert_includes recipients, subscribers(:confirmed)
    assert_not_includes recipients, subscribers(:unconfirmed)
    assert_not_includes recipients, subscribers(:with_token)
    assert_equal [ subscribers(:confirmed) ], mailing_lists(:deep_dives).recipients.to_a
  end

  test "subscriber_counts counts only confirmed subscribers per list" do
    counts = MailingList.subscriber_counts

    assert_equal mailing_lists(:main).recipients.count, counts[mailing_lists(:main).id]
    assert_equal 1, counts[mailing_lists(:deep_dives).id]
  end

  test "destroying a list removes memberships and detaches campaigns" do
    list = mailing_lists(:deep_dives)
    newsletter = newsletters(:draft_newsletter)
    newsletter.update!(mailing_list: list)

    list.destroy

    assert_nil newsletter.reload.mailing_list_id
    assert_empty MailingListSubscription.where(mailing_list_id: list.id)
    assert_empty MailingListPost.where(mailing_list_id: list.id)
  end
end
