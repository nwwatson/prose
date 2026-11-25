require "test_helper"

class Admin::PaginationTest < ActionDispatch::IntegrationTest
  setup { sign_in_as(:admin) }

  test "subscribers index shows one page and links to the others" do
    paged(2) do
      get admin_subscribers_path
      assert_select "tbody tr", 2
      assert_select "a[rel=prev]", false
      assert_select "a[rel=next][href=?]", "/admin/subscribers?page=2"

      get admin_subscribers_path(page: 3)
      assert_select "tbody tr", Subscriber.count - 4
      assert_select "a[rel=prev][href=?]", "/admin/subscribers?page=2"
      assert_select "a[rel=next]", false
    end
  end

  test "subscriber search and label filters survive paging" do
    paged(1) do
      get admin_subscribers_path(label: subscriber_labels(:vip).id, search: "example")

      assert_select "tbody tr", 1
      assert_select "a[rel=next][href=?]",
        "/admin/subscribers?label=#{subscriber_labels(:vip).id}&page=2&search=example"
    end
  end

  test "filtering by label still shows every label a subscriber has" do
    get admin_subscribers_path(label: subscriber_labels(:vip).id)

    assert_select "tbody span", text: subscriber_labels(:beta_tester).name
  end

  test "posts index paginates both layouts and keeps the status filter" do
    paged(1) do
      get admin_posts_path(status: "published")

      assert_select "[data-testid=mobile-post-cards] > a", 1
      assert_select "[data-testid=desktop-post-table] tbody tr", 1
      assert_select "a[rel=next][href=?]", "/admin/posts?page=2&status=published"
    end
  end

  test "comments index paginates and keeps the filter" do
    paged(1) do
      get admin_comments_path(filter: "approved")

      assert_select ".prose-comment", 1
      assert_select "a[rel=next][href=?]", "/admin/comments?filter=approved&page=2"
    end
  end

  test "memberships index paginates and keeps the status filter" do
    Membership.grant_complimentary!(subscriber: subscribers(:from_featured_post), membership_tier: membership_tiers(:monthly))
    Membership.grant_complimentary!(subscriber: subscribers(:from_published_post), membership_tier: membership_tiers(:monthly))

    paged(1) do
      get admin_memberships_path(status: "active")

      assert_select "tbody tr", 1
      assert_select "a[rel=next][href=?]", "/admin/memberships?page=2&status=active"
    end
  end

  test "newsletter delivery log paginates while the stats count every delivery" do
    newsletter = newsletters(:sent_newsletter)

    paged(2) do
      get admin_newsletter_path(newsletter)

      assert_select "tbody tr", 2
      assert_select "a[rel=next][href=?]", "/admin/newsletters/#{newsletter.id}?page=2"
      assert_select "div.text-2xl", text: newsletter.newsletter_deliveries.count.to_s
    end
  end

  test "segment page shows the full matching count when paginated" do
    segment = segments(:vip_segment)
    assert_operator segment.subscriber_count, :>, 1

    paged(1) do
      get admin_segment_path(segment)

      assert_select "tbody tr", 1
      assert_select "p.text-2xl", text: segment.subscriber_count.to_s
      assert_select "a[rel=next]"
    end
  end

  test "newsletters and segments indexes paginate" do
    paged(1) do
      get admin_newsletters_path
      assert_select "tbody tr", 1
      assert_select "a[rel=next]"

      get admin_segments_path
      assert_select "tbody tr", 1
      assert_select "a[rel=next]"
    end
  end

  test "a page past the end still links back" do
    get admin_comments_path(page: 9)

    assert_response :success
    assert_select "a[rel=prev][href=?]", "/admin/comments?page=8"
  end

  test "no pagination controls when everything fits on one page" do
    get admin_subscribers_path

    assert_select "[data-testid=pagination]", false
  end

  private

  def paged(per_page, &block)
    with_const(Admin::BaseController, :PER_PAGE, per_page, &block)
  end
end
