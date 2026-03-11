require "test_helper"

class SendNewsletterJobSegmentedTest < ActiveSupport::TestCase
  test "sends to all confirmed subscribers when no segment" do
    newsletter = newsletters(:draft_newsletter)
    newsletter.update!(status: :sending, sent_at: Time.current)

    assert_difference "NewsletterDelivery.count", Subscriber.confirmed.count do
      SendNewsletterJob.new.perform(newsletter.id)
    end
  end

  test "sends only to segment subscribers when segment set" do
    segment = segments(:vip_segment)
    newsletter = newsletters(:draft_newsletter)
    newsletter.update!(status: :sending, sent_at: Time.current, segment: segment)

    expected_count = segment.resolve.count
    assert expected_count > 0, "VIP segment should have subscribers"
    assert expected_count < Subscriber.confirmed.count, "Segment should be a subset"

    assert_difference "NewsletterDelivery.count", expected_count do
      SendNewsletterJob.new.perform(newsletter.id)
    end
  end

  test "target_subscribers returns segment subscribers when segment present" do
    segment = segments(:vip_segment)
    newsletter = newsletters(:draft_newsletter)
    newsletter.segment = segment

    assert_equal segment.resolve.count, newsletter.target_subscribers.count
  end

  test "target_subscribers returns all confirmed when no segment" do
    newsletter = newsletters(:draft_newsletter)
    assert_equal Subscriber.confirmed.count, newsletter.target_subscribers.count
  end
end
