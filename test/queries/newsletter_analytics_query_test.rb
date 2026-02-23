require "test_helper"

class NewsletterAnalyticsQueryTest < ActiveSupport::TestCase
  setup do
    @newsletter = newsletters(:sent_newsletter)
    @query = NewsletterAnalyticsQuery.new(@newsletter)
  end

  test "deliveries_count returns total deliveries" do
    assert_equal @newsletter.newsletter_deliveries.count, @query.deliveries_count
  end

  test "opens_count returns deliveries with opened_at" do
    expected = @newsletter.newsletter_deliveries.where.not(opened_at: nil).count
    assert_equal expected, @query.opens_count
  end

  test "clicks_count returns deliveries with clicked_at" do
    expected = @newsletter.newsletter_deliveries.where.not(clicked_at: nil).count
    assert_equal expected, @query.clicks_count
  end

  test "bounces_count returns deliveries with bounced_at" do
    expected = @newsletter.newsletter_deliveries.where.not(bounced_at: nil).count
    assert_equal expected, @query.bounces_count
  end

  test "open_rate calculates percentage" do
    rate = @query.open_rate
    assert_kind_of Float, rate
    assert rate >= 0.0
    assert rate <= 100.0
  end

  test "click_rate calculates percentage" do
    rate = @query.click_rate
    assert_kind_of Float, rate
    assert rate >= 0.0
    assert rate <= 100.0
  end

  test "bounce_rate calculates percentage" do
    rate = @query.bounce_rate
    assert_kind_of Float, rate
    assert rate >= 0.0
    assert rate <= 100.0
  end

  test "rates return 0 for newsletter with no deliveries" do
    newsletter = newsletters(:draft_newsletter)
    query = NewsletterAnalyticsQuery.new(newsletter)
    assert_equal 0.0, query.open_rate
    assert_equal 0.0, query.click_rate
    assert_equal 0.0, query.bounce_rate
  end
end
