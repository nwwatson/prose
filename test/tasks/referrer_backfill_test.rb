require "test_helper"
require "rake"

class ReferrerBackfillTest < ActiveSupport::TestCase
  setup do
    Rails.application.load_tasks unless Rake::Task.task_defined?("referrer:backfill")
    Rake::Task["referrer:backfill"].reenable
  end

  test "backfills referrer_domain and UTM columns without overwriting source" do
    post = posts(:published_post)
    view = PostView.create!(
      post: post,
      ip_hash: "backfill-test",
      referrer: "https://www.google.com/search?utm_source=newsletter&utm_medium=email&utm_campaign=launch",
      source: "direct",
      referrer_domain: nil
    )

    out, = capture_io { Rake::Task["referrer:backfill"].invoke }

    view.reload
    assert_equal "google.com", view.referrer_domain
    assert_equal "newsletter", view.utm_source
    assert_equal "email", view.utm_medium
    assert_equal "launch", view.utm_campaign
    assert_equal "direct", view.source
    assert_match(/Done\. Updated 1 records\./, out)
  end
end
