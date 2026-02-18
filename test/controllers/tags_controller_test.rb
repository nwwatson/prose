require "test_helper"

class TagsControllerTest < ActionDispatch::IntegrationTest
  test "GET show renders tag with posts" do
    get tag_path(tags(:ruby), slug: tags(:ruby).slug)
    assert_response :success
    assert_select "h1", /Ruby/
  end
end
