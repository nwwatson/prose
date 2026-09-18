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

  test "import_reading_list! ignores blank input" do
    assert_no_difference "ReadingListItem.count" do
      @identity.import_reading_list!(nil)
      @identity.import_reading_list!([])
    end
  end

  test "reading list items are destroyed with the identity" do
    assert_equal :destroy, Identity.reflect_on_association(:reading_list_items).options[:dependent]
  end
end
