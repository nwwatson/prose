require "test_helper"

class Admin::PagesControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_as(:admin)
  end

  test "GET index lists pages" do
    get admin_pages_path
    assert_response :success
    assert_select "table"
  end

  test "GET new renders form" do
    get new_admin_page_path
    assert_response :success
    assert_select "form"
  end

  test "POST create creates a draft page" do
    assert_difference "Page.count", 1 do
      post admin_pages_path, params: { page: { title: "New Test Page" } }
    end
    assert_redirected_to edit_admin_page_path(Page.last)
    assert Page.last.draft?
  end

  test "POST create with invalid data re-renders form" do
    post admin_pages_path, params: { page: { title: "" } }
    assert_response :unprocessable_entity
  end

  test "GET edit renders form" do
    get edit_admin_page_path(pages(:draft_page))
    assert_response :success
  end

  test "PATCH update updates page" do
    patch admin_page_path(pages(:draft_page)), params: { page: { title: "Updated Title" } }
    assert_redirected_to edit_admin_page_path(pages(:draft_page))
    assert_equal "Updated Title", pages(:draft_page).reload.title
  end

  test "DELETE destroy removes page" do
    assert_difference "Page.count", -1 do
      delete admin_page_path(pages(:draft_page))
    end
    assert_redirected_to admin_pages_path
  end

  test "POST create as JSON returns created with page data" do
    assert_difference "Page.count", 1 do
      post admin_pages_path, params: { page: { title: "Autosaved Page" } }, as: :json
    end
    assert_response :created
    json = JSON.parse(response.body)
    assert json["slug"].present?
    assert json["url"].present?
    assert json["edit_url"].present?
  end

  test "POST create as JSON with blank title returns errors" do
    post admin_pages_path, params: { page: { title: "" } }, as: :json
    assert_response :unprocessable_entity
    json = JSON.parse(response.body)
    assert json["errors"].any?
  end

  test "PATCH update as JSON returns ok with page data" do
    patch admin_page_path(pages(:draft_page)), params: { page: { title: "Updated via JSON" } }, as: :json
    assert_response :ok
    json = JSON.parse(response.body)
    assert json["slug"].present?
    assert json["url"].present?
    assert json["edit_url"].present?
    assert_equal "Updated via JSON", pages(:draft_page).reload.title
  end

  test "PATCH update as JSON with blank title returns errors" do
    patch admin_page_path(pages(:draft_page)), params: { page: { title: "" } }, as: :json
    assert_response :unprocessable_entity
    json = JSON.parse(response.body)
    assert json["errors"].any?
  end

  test "requires authentication" do
    delete admin_session_path
    get admin_pages_path
    assert_redirected_to new_admin_session_path
  end
end
