require "test_helper"

class Subscriber::SearchTest < ActiveSupport::TestCase
  test "search matches part of the email or the handle" do
    subscriber = subscribers(:confirmed)

    assert_includes Subscriber.search("subscriber@"), subscriber
    subscriber.identity.update!(handle: "quietreader")
    assert_equal [ subscriber ], Subscriber.search("etread").to_a
  end

  test "search treats LIKE wildcards literally" do
    subscriber = Subscriber.create!(email: "under_score@example.com")

    assert_equal [ subscriber ], Subscriber.search("r_s").to_a
    assert_empty Subscriber.search("%")
  end

  test "with_label returns labeled subscribers" do
    assert_equal subscribers(:confirmed, :with_token).sort_by(&:id),
      Subscriber.with_label(subscriber_labels(:vip).id).order(:id).to_a
  end

  test "blank arguments do not filter" do
    assert_equal Subscriber.count, Subscriber.search(nil).with_label("").count
  end
end
