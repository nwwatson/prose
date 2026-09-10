require "test_helper"

class Admin::CategoriesControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_as(:admin)
  end

  test "GET index lists categories" do
    get admin_categories_path
    assert_response :success
  end

  test "GET index runs a single grouped count query regardless of category count" do
    5.times { |i| Category.create!(name: "Extra #{i}") }

    post_queries = 0
    callback = lambda do |*, payload|
      post_queries += 1 if payload[:sql].match?(/FROM "posts"/)
    end

    ActiveSupport::Notifications.subscribed(callback, "sql.active_record") do
      get admin_categories_path
    end

    assert_response :success
    assert_equal 1, post_queries
  end

  test "GET new renders form" do
    get new_admin_category_path
    assert_response :success
  end

  test "POST create creates category" do
    assert_difference "Category.count", 1 do
      post admin_categories_path, params: { category: { name: "Science" } }
    end
    assert_redirected_to admin_categories_path
  end

  test "GET edit renders form" do
    get edit_admin_category_path(categories(:technology))
    assert_response :success
  end

  test "PATCH update updates category" do
    patch admin_category_path(categories(:technology)), params: { category: { name: "Tech" } }
    assert_redirected_to admin_categories_path
    assert_equal "Tech", categories(:technology).reload.name
  end

  test "DELETE destroy removes category" do
    assert_difference "Category.count", -1 do
      delete admin_category_path(categories(:design))
    end
    assert_redirected_to admin_categories_path
  end
end
