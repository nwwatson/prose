require "test_helper"

class ReadingListHelperTest < ActionView::TestCase
  test "the meta tag reads the signed-in reader's ids once per request" do
    identity = identities(:subscriber_identity)
    define_singleton_method(:identity_signed_in?) { true }
    define_singleton_method(:current_identity) { identity }

    assert_query_count(1, table: "reading_list_items") do
      2.times { reading_list_meta_tag }
    end
  end
end
