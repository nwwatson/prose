require "test_helper"

class NavigationItem::CacheableTest < ActiveSupport::TestCase
  test "for_location returns ordered items for one location" do
    assert_equal [ navigation_items(:home), navigation_items(:about) ], NavigationItem.for_location(:header)
    assert_equal [ navigation_items(:github) ], NavigationItem.for_location("social")
  end

  test "one query serves every location for the rest of the request" do
    assert_queries_count(1) do
      NavigationItem.locations.each_key { |location| NavigationItem.for_location(location) }
      NavigationItem.for_location(:header)
    end
  end

  test "a location with no items is empty" do
    NavigationItem.footer.delete_all
    assert_empty NavigationItem.for_location(:footer)
  end

  test "the next request reads fresh items" do
    NavigationItem.for_location(:header)
    NavigationItem.reposition!(:header, [ navigation_items(:about).id, navigation_items(:home).id ])

    Current.reset

    assert_equal navigation_items(:about), NavigationItem.for_location(:header).first
  end
end
