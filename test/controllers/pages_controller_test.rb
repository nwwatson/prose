require "test_helper"

class PagesControllerTest < ActionDispatch::IntegrationTest
  test "GET about renders" do
    get about_path
    assert_response :success
    assert_select "h1", /About/
  end
end
