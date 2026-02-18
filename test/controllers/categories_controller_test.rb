require "test_helper"

class CategoriesControllerTest < ActionDispatch::IntegrationTest
  test "GET show renders category with posts" do
    get category_path(categories(:technology), slug: categories(:technology).slug)
    assert_response :success
    assert_select "h1", text: categories(:technology).name
  end

  test "GET show returns 404 for unknown slug" do
    get category_path("nonexistent", slug: "nonexistent")
    assert_response :not_found
  end
end
