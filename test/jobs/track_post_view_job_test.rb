require "test_helper"

class TrackPostViewJobTest < ActiveSupport::TestCase
  test "creates a post view with UTM params extracted from referrer" do
    post = posts(:published_post)
    referrer = "https://example.com/page?utm_source=newsletter&utm_medium=email&utm_campaign=launch"

    assert_difference "PostView.count" do
      TrackPostViewJob.new.perform(
        post_id: post.id,
        ip_address: "1.2.3.4",
        referrer: referrer
      )
    end

    view = PostView.last
    assert_equal "newsletter", view.utm_source
    assert_equal "email", view.utm_medium
    assert_equal "launch", view.utm_campaign
    assert_equal "example.com", view.referrer_domain
    assert_equal "other", view.source
  end

  test "extracts domain without www prefix" do
    post = posts(:published_post)

    TrackPostViewJob.new.perform(
      post_id: post.id,
      ip_address: "1.2.3.4",
      referrer: "https://www.google.com/search?q=test"
    )

    view = PostView.last
    assert_equal "google.com", view.referrer_domain
    assert_equal "google", view.source
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

  test "handles invalid URI gracefully" do
    post = posts(:published_post)

    TrackPostViewJob.new.perform(
      post_id: post.id,
      ip_address: "1.2.3.4",
      referrer: "not a valid uri %%"
    )

    view = PostView.last
    assert_equal "other", view.source
  end

  test "truncates long UTM values" do
    post = posts(:published_post)
    long_campaign = "x" * 300

    TrackPostViewJob.new.perform(
      post_id: post.id,
      ip_address: "1.2.3.4",
      referrer: "https://example.com?utm_campaign=#{long_campaign}"
    )

    view = PostView.last
    assert view.utm_campaign.length <= 255
  end

  test "extracts twitter source from x.com" do
    post = posts(:published_post)

    TrackPostViewJob.new.perform(
      post_id: post.id,
      ip_address: "1.2.3.4",
      referrer: "https://x.com/user/status/123"
    )

    view = PostView.last
    assert_equal "twitter", view.source
    assert_equal "x.com", view.referrer_domain
  end

  test "referrer with no query params has nil UTM fields" do
    post = posts(:published_post)

    TrackPostViewJob.new.perform(
      post_id: post.id,
      ip_address: "1.2.3.4",
      referrer: "https://www.reddit.com/r/rails"
    )

    view = PostView.last
    assert_equal "reddit", view.source
    assert_nil view.utm_source
    assert_nil view.utm_medium
    assert_nil view.utm_campaign
  end
end
