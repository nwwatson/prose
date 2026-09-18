require "test_helper"

class Admin::NavigationItemsControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_as(:admin)
  end

  test "GET index renders all three sections" do
    get admin_navigation_items_path
    assert_response :success
    assert_select "section#header li", 2
    assert_select "section#footer li", 1
    assert_select "section#social li", 1
    assert_select "form[action='#{admin_navigation_items_path}']", 3
  end

  test "POST create adds an item to the end of its location" do
    assert_difference "NavigationItem.header.count", 1 do
      post admin_navigation_items_path, params: { navigation_item: { label: "Contact", url: "/contact", location: "header", open_in_new_tab: "1" } }
    end

    item = NavigationItem.order(:id).last
    assert_redirected_to admin_navigation_items_path(anchor: "header")
    assert_equal 2, item.position
    assert item.open_in_new_tab?
  end

  test "POST create with an invalid URL re-renders with errors in that section" do
    assert_no_difference "NavigationItem.count" do
      post admin_navigation_items_path, params: { navigation_item: { label: "Bad", url: "javascript:alert(1)", location: "footer" } }
    end

    assert_response :unprocessable_entity
    assert_select "section#footer .bg-red-50"
    assert_select "section#header .bg-red-50", 0
  end

  test "GET edit renders form" do
    get edit_admin_navigation_item_path(navigation_items(:about))
    assert_response :success
  end

  test "PATCH update changes the item" do
    patch admin_navigation_item_path(navigation_items(:about)), params: { navigation_item: { label: "About", url: "/about" } }
    assert_redirected_to admin_navigation_items_path(anchor: "header")
    assert_equal "About", navigation_items(:about).reload.label
  end

  test "PATCH update with invalid data re-renders edit" do
    patch admin_navigation_item_path(navigation_items(:about)), params: { navigation_item: { url: "" } }
    assert_response :unprocessable_entity
  end

  test "DELETE destroy removes the item" do
    assert_difference "NavigationItem.count", -1 do
      delete admin_navigation_item_path(navigation_items(:privacy))
    end
    assert_redirected_to admin_navigation_items_path(anchor: "footer")
  end

  test "PATCH move reorders within a location" do
    patch move_admin_navigation_item_path(navigation_items(:about), direction: "up")
    assert_redirected_to admin_navigation_items_path(anchor: "header")
    assert_equal [ navigation_items(:about), navigation_items(:home) ], NavigationItem.header.ordered.to_a
  end

  test "PATCH reorder saves the dragged order" do
    patch reorder_admin_navigation_items_path, params: { location: "header", ids: [ navigation_items(:about).id, navigation_items(:home).id ] }, as: :json
    assert_response :no_content
    assert_equal [ navigation_items(:about), navigation_items(:home) ], NavigationItem.header.ordered.to_a
  end

  test "PATCH reorder rejects an unknown location" do
    patch reorder_admin_navigation_items_path, params: { location: "sidebar", ids: [] }, as: :json
    assert_response :unprocessable_entity
  end

  test "writers cannot manage navigation" do
    delete admin_session_path
    sign_in_as(:writer)

    get admin_navigation_items_path
    assert_redirected_to admin_root_path

    assert_no_difference "NavigationItem.count" do
      post admin_navigation_items_path, params: { navigation_item: { label: "X", url: "/x", location: "header" } }
    end

    patch reorder_admin_navigation_items_path, params: { location: "header", ids: [ navigation_items(:about).id ] }, as: :json
    assert_equal navigation_items(:home), NavigationItem.header.ordered.first
  end
end
