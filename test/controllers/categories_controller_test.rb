require "test_helper"

class CategoriesControllerTest < ActionDispatch::IntegrationTest
  test "GET show renders category with posts" do
    get category_path(slug: categories(:technology).slug)
    assert_response :success
    assert_select "h1", text: categories(:technology).name
  end

  test "GET show returns 404 for unknown slug" do
    get category_path(slug: "nonexistent")
    assert_response :not_found
  end
end
