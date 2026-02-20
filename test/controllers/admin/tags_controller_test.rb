require "test_helper"

class Admin::TagsControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_as(:admin)
  end

  test "POST create creates a new tag and returns JSON" do
    assert_difference "Tag.count", 1 do
      post admin_tags_path, params: { tag: { name: "JavaScript" } }, as: :json
    end

    assert_response :success
    json = JSON.parse(response.body)
    assert_equal "JavaScript", json["name"]
    assert_equal "javascript", json["slug"]
    assert json["id"].present?
  end

  test "POST create returns existing tag when name matches" do
    existing = tags(:ruby)

    assert_no_difference "Tag.count" do
      post admin_tags_path, params: { tag: { name: "Ruby" } }, as: :json
    end

    assert_response :success
    json = JSON.parse(response.body)
    assert_equal existing.id, json["id"]
    assert_equal "Ruby", json["name"]
  end

  test "POST create strips whitespace from name" do
    assert_difference "Tag.count", 1 do
      post admin_tags_path, params: { tag: { name: "  Elixir  " } }, as: :json
    end

    assert_response :success
    json = JSON.parse(response.body)
    assert_equal "Elixir", json["name"]
    assert_equal "elixir", json["slug"]
  end

  test "POST create returns 422 for blank name" do
    assert_no_difference "Tag.count" do
      post admin_tags_path, params: { tag: { name: "  " } }, as: :json
    end

    assert_response :unprocessable_entity
    json = JSON.parse(response.body)
    assert json["errors"].any? { |e| e.include?("Name") }
  end

  test "POST create requires authentication" do
    delete admin_session_path

    post admin_tags_path, params: { tag: { name: "Go" } }, as: :json

    assert_response :redirect
  end
end
