require "test_helper"

class Identity::ReadingListableTest < ActiveSupport::TestCase
  setup do
    @identity = identities(:subscriber_identity)
  end

  test "reading_list_post_ids lists live saved posts newest first" do
    assert_equal [ posts(:featured_post).id, posts(:published_post).id ], @identity.reading_list_post_ids
  end

  test "reading_list_posts returns live saved posts newest first" do
    assert_equal [ posts(:featured_post), posts(:published_post) ], @identity.reading_list_posts.to_a
  end

  test "bookmark! saves a post and is idempotent" do
    assert_difference "@identity.reading_list_items.count", 1 do
      @identity.bookmark!(posts(:design_post))
      @identity.bookmark!(posts(:design_post))
    end

    assert_equal posts(:design_post).id, @identity.reading_list_post_ids.first
  end

  test "unbookmark! accepts a post or a post id" do
    @identity.unbookmark!(posts(:published_post))
    @identity.unbookmark!(posts(:featured_post).id)

    assert_empty @identity.reading_list_post_ids
  end

  test "import_reading_list! merges live posts and keeps the browser's order" do
    other = identities(:with_token_identity)
    newest_first = [ posts(:design_post).id, posts(:related_ruby_post).id ]

    other.import_reading_list!(newest_first.map(&:to_s))

    assert_equal newest_first, other.reading_list_post_ids
  end

  test "import_reading_list! skips drafts, unknown ids, junk, and posts already saved" do
    assert_difference "@identity.reading_list_items.count", 1 do
      @identity.import_reading_list!([ posts(:draft_post).id, posts(:published_post).id, 0, -4, "junk", 999_999, posts(:design_post).id ])
    end

    assert_includes @identity.reading_list_post_ids, posts(:design_post).id
  end

  test "import_reading_list! runs the same statements however many ids it gets" do
    other = identities(:with_token_identity)
    one = [ posts(:design_post).id ]
    several = [ posts(:related_ruby_post).id, posts(:published_post).id, posts(:featured_post).id ]

    single = count_queries { other.import_reading_list!(one) }
    writes = nil
    batch = count_queries { writes = capture_writes("reading_list_items") { other.import_reading_list!(several) } }

    assert_equal single, batch
    assert_equal 1, writes.size
    assert_equal several + one, other.reading_list_post_ids
  end

  test "import_reading_list! keeps the newest ids that fit under the cap" do
    ids = [ posts(:design_post).id, posts(:related_ruby_post).id ]

    with_reading_list_limit(@identity.reading_list_items.count + 1) do
      @identity.import_reading_list!(ids)
      @identity.import_reading_list!(ids)
    end

    assert_equal ids.first, @identity.reading_list_post_ids.first
    assert_not_includes @identity.reading_list_post_ids, ids.last
  end

  test "import_reading_list! updates an already loaded association" do
    @identity.reading_list_items.load

    @identity.import_reading_list!([ posts(:design_post).id ])

    assert_includes @identity.reading_list_items.map(&:post_id), posts(:design_post).id
  end

  test "import_reading_list! ignores blank input" do
    assert_no_difference "ReadingListItem.count" do
      @identity.import_reading_list!(nil)
      @identity.import_reading_list!([])
    end
  end

  test "reading list items are destroyed with the identity" do
    assert_equal :delete_all, Identity.reflect_on_association(:reading_list_items).options[:dependent]
  end

  private

  def count_queries(&block)
    count = 0
    counter = ->(*, payload) { count += 1 unless payload[:name] == "SCHEMA" }
    ActiveSupport::Notifications.subscribed(counter, "sql.active_record", &block)
    count
  end
end
