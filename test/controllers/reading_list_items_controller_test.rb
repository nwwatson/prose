require "test_helper"

class ReadingListItemsControllerTest < ActionDispatch::IntegrationTest
  test "create requires a signed-in identity" do
    assert_no_difference "ReadingListItem.count" do
      post reading_list_items_path, params: { post_id: posts(:design_post).id }, as: :json
    end

    assert_response :unauthorized
    assert response.parsed_body["error"].present?
  end

  test "create saves a post and returns the updated list" do
    sign_in_subscriber(subscribers(:confirmed))

    assert_difference "ReadingListItem.count", 1 do
      post reading_list_items_path, params: { post_id: posts(:design_post).id }, as: :json
    end

    assert_response :created
    assert_equal posts(:design_post).id, response.parsed_body["post_ids"].first
  end

  test "create is idempotent" do
    sign_in_subscriber(subscribers(:confirmed))

    assert_no_difference "ReadingListItem.count" do
      post reading_list_items_path, params: { post_id: posts(:published_post).id }, as: :json
    end

    assert_response :created
  end

  test "create refuses posts that are not live" do
    sign_in_subscriber(subscribers(:with_token))

    assert_no_difference "ReadingListItem.count" do
      post reading_list_items_path, params: { post_id: posts(:scheduled_post).id }, as: :json
    end

    assert_response :not_found
  end

  test "create reports a full list as unprocessable" do
    sign_in_subscriber(subscribers(:confirmed))
    with_reading_list_limit(3) do
      post reading_list_items_path, params: { post_id: posts(:design_post).id }, as: :json
    end

    assert_response :unprocessable_entity
    assert_match "full", response.parsed_body["error"]
  end

  test "create works for staff users" do
    sign_in_as(:admin)

    assert_difference "users(:admin).identity.reading_list_items.count", 1 do
      post reading_list_items_path, params: { post_id: posts(:design_post).id }, as: :json
    end
  end

  test "destroy removes a saved post, including one since unpublished" do
    sign_in_subscriber(subscribers(:confirmed))

    assert_difference "ReadingListItem.count", -1 do
      delete reading_list_item_path(posts(:draft_post).id), as: :json
    end

    assert_response :success
    assert_equal [ posts(:featured_post).id, posts(:published_post).id ], response.parsed_body["post_ids"]
  end

  test "destroy only touches the current reader's list" do
    sign_in_subscriber(subscribers(:with_token))

    assert_no_difference "ReadingListItem.count" do
      delete reading_list_item_path(posts(:published_post).id), as: :json
    end
  end

  test "destroy requires a signed-in identity" do
    assert_no_difference "ReadingListItem.count" do
      delete reading_list_item_path(posts(:published_post).id), as: :json
    end

    assert_response :unauthorized
  end
end
