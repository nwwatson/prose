require "test_helper"

class PagesControllerTest < ActionDispatch::IntegrationTest
  test "GET show renders a published page" do
    get page_path(pages(:published_page).slug)
    assert_response :success
    assert_select "h1", pages(:published_page).title
  end

  test "GET show returns 404 for draft page" do
    get page_path(pages(:draft_page).slug)
    assert_response :not_found
  end

  test "GET show returns 404 for nonexistent slug" do
    get page_path("nonexistent-page")
    assert_response :not_found
  end
end
