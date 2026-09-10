require "test_helper"

class TrackPostViewJobTest < ActiveSupport::TestCase
  test "creates a post view with fields from the parsed referrer" do
    post = posts(:published_post)
    referrer = "https://www.google.com/search?q=test&utm_source=newsletter&utm_medium=email&utm_campaign=launch"

    assert_difference "PostView.count" do
      TrackPostViewJob.new.perform(
        post_id: post.id,
        ip_address: "1.2.3.4",
        referrer: referrer
      )
    end

    view = PostView.last
    assert_equal "google", view.source
    assert_equal "google.com", view.referrer_domain
    assert_equal "newsletter", view.utm_source
    assert_equal "email", view.utm_medium
    assert_equal "launch", view.utm_campaign
  end

  test "handles blank referrer as direct" do
    post = posts(:published_post)

    TrackPostViewJob.new.perform(
      post_id: post.id,
      ip_address: "1.2.3.4",
      referrer: nil
    )

    view = PostView.last
    assert_equal "direct", view.source
    assert_nil view.referrer_domain
    assert_nil view.utm_source
  end
end
