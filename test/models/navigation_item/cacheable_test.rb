require "test_helper"

class NavigationItem::CacheableTest < ActiveSupport::TestCase
  setup do
    @original_cache = Rails.cache
    Rails.cache = ActiveSupport::Cache::MemoryStore.new
  end

  teardown do
    Rails.cache = @original_cache
  end

  test "for_location returns ordered items for one location" do
    assert_equal [ navigation_items(:home), navigation_items(:about) ], NavigationItem.for_location(:header)
    assert_equal [ navigation_items(:github) ], NavigationItem.for_location("social")
  end

  test "for_location serves from cache on repeat calls" do
    NavigationItem.for_location(:header)
    assert_no_queries { NavigationItem.for_location(:header) }
  end

  test "saving an item expires the cache" do
    NavigationItem.for_location(:header)
    navigation_items(:home).update!(label: "Start")
    assert_equal "Start", NavigationItem.for_location(:header).first.label
  end

  test "destroying an item expires the cache" do
    NavigationItem.for_location(:header)
    navigation_items(:about).destroy!
    assert_equal [ navigation_items(:home) ], NavigationItem.for_location(:header)
  end

  test "reposition! expires the cache" do
    NavigationItem.for_location(:header)
    NavigationItem.reposition!(:header, [ navigation_items(:about).id, navigation_items(:home).id ])
    assert_equal navigation_items(:about), NavigationItem.for_location(:header).first
  end
end
