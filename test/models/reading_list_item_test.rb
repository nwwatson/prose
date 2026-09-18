require "test_helper"

class ReadingListItemTest < ActiveSupport::TestCase
  test "a post can only be saved once per identity" do
    duplicate = ReadingListItem.new(identity: identities(:subscriber_identity), post: posts(:published_post))

    assert_not duplicate.valid?
    assert duplicate.errors.of_kind?(:post_id, :taken)
  end

  test "different identities can save the same post" do
    item = ReadingListItem.new(identity: identities(:with_token_identity), post: posts(:published_post))

    assert item.valid?
  end

  test "rejects new items once the list is full" do
    with_reading_list_limit(3) do
      item = ReadingListItem.new(identity: identities(:subscriber_identity), post: posts(:design_post))

      assert_not item.valid?
      assert item.errors.of_kind?(:base, :reading_list_full)
    end
  end

  test "newest_first orders by save time descending" do
    ids = identities(:subscriber_identity).reading_list_items.newest_first.map(&:post)

    assert_equal [ posts(:draft_post), posts(:featured_post), posts(:published_post) ], ids
  end

  test "is removed with its post" do
    assert_difference "ReadingListItem.count", -1 do
      posts(:featured_post).destroy
    end
  end
end
