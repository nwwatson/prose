require "test_helper"

class Admin::CategoriesControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_as(:admin)
  end

  test "GET index lists categories" do
    get admin_categories_path
    assert_response :success
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
