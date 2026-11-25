require "test_helper"

# Public listing pages: bounded pages of posts, and post cards rendered as one
# cached collection (a single read_multi per listing, not a read per card).
class PostCardListingTest < ActionDispatch::IntegrationTest
  setup do
    @category = categories(:technology)
    @tag = tags(:ruby)
    @author = users(:admin)
    @extra_posts = Array.new(12) do |i|
      Post.create!(title: "Listing Post #{i}", subtitle: "Listing subtitle #{i}", slug: "listing-post-#{i}",
        status: :published, published_at: (i + 1).minutes.ago, user: @author, category: @category,
        tags: [ @tag ], body_plain: "Body #{i}", subscribers_notified_at: Time.current)
    end
  end

  test "category pages are paginated with an infinite-scroll frame" do
    get category_path(slug: @category.slug)

    assert_response :success
    assert_select "turbo-frame#posts_page_1 .post-card", count: 10
    assert_select "turbo-frame#posts_page_2 a[href=?]", "/categories/#{@category.slug}?page=2"
  end

  test "the next category page answers its turbo frame without the layout" do
    get category_path(slug: @category.slug, page: 2), headers: { "Turbo-Frame" => "posts_page_2" }

    assert_response :success
    assert_select "turbo-frame#posts_page_2 .post-card"
    assert_select "header.masthead", count: 0
    assert_select "turbo-frame#posts_page_3", count: 0
  end

  test "tag pages are paginated with an infinite-scroll frame" do
    get tag_path(slug: @tag.slug)

    assert_response :success
    assert_select "turbo-frame#posts_page_1 .post-card", count: 10
    assert_select "turbo-frame#posts_page_2 a[href=?]", "/tags/#{@tag.slug}?page=2"

    get tag_path(slug: @tag.slug, page: 2), headers: { "Turbo-Frame" => "posts_page_2" }
    assert_select "turbo-frame#posts_page_2 .post-card"
  end

  test "the signed-in reading list is paginated" do
    subscriber = subscribers(:with_token)
    @extra_posts.each { |post| subscriber.identity.bookmark!(post) }
    sign_in_subscriber(subscriber)

    get reading_list_path

    assert_select "turbo-frame#posts_page_1 .post-card", count: 10
    assert_select "turbo-frame#posts_page_2 a[href=?]", "/reading-list?page=2"

    get reading_list_path(page: 2), headers: { "Turbo-Frame" => "posts_page_2" }
    assert_select "turbo-frame#posts_page_2 .post-card", count: 2
    assert_select "turbo-frame#posts_page_3", count: 0
  end

  test "each listing reads its cards with one read_multi and no per-card reads" do
    with_fragment_caching do
      { category_path(slug: @category.slug) => 1, tag_path(slug: @tag.slug) => 1,
        root_path => 2 } # the featured post hero is its own collection
        .each do |path, collections|
          2.times do # cold, then warm
            reads = capture_fragment_reads { get path }

            assert_response :success
            assert_equal collections, reads[:read_multi].size, path
            assert_empty reads[:single], path
            assert_operator reads[:read_multi].sum, :>=, 10, path
          end
        end
    end
  end

  test "cards cached for one listing are not reused by a listing with other card options" do
    with_fragment_caching do
      get category_path(slug: @category.slug) # hides subtitles
      assert_select ".post-card__subtitle", count: 0

      get root_path
      assert_select ".post-card__subtitle", text: "Listing subtitle 0"
    end
  end

  test "cached cards follow a site locale change" do
    with_fragment_caching do
      get root_path
      assert_select ".post-card .post-meta", text: /min read/

      SiteSetting.current.update!(locale: "es")
      get root_path
      assert_select ".post-card .post-meta", text: /min de lectura/
    end
  end

  private

  def capture_fragment_reads(&block)
    reads = { read_multi: [], single: [] }
    callbacks = {
      "cache_read_multi.active_support" => ->(event) {
        keys = Array(event.payload[:key])
        reads[:read_multi] << keys.size if keys.any? { |key| key.to_s.start_with?("views/") }
      },
      "cache_read.active_support" => ->(event) { reads[:single] << event.payload[:key] if event.payload[:key].to_s.start_with?("views/") },
      "read_fragment.action_controller" => ->(event) { reads[:single] << event.payload[:key] }
    }
    callbacks.reduce(block) { |inner, (name, callback)| -> { ActiveSupport::Notifications.subscribed(callback, name, &inner) } }.call
    reads
  end
end
