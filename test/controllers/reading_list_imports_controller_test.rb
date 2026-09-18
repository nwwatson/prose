require "test_helper"

class ReadingListImportsControllerTest < ActionDispatch::IntegrationTest
  test "merges browser-saved ids into the account and returns the list" do
    sign_in_subscriber(subscribers(:with_token))
    ids = [ posts(:design_post).id, posts(:published_post).id ]

    post reading_list_import_path, params: { post_ids: ids }, as: :json

    assert_response :success
    assert_equal ids, response.parsed_body["post_ids"]
  end

  test "requires a signed-in identity" do
    assert_no_difference "ReadingListItem.count" do
      post reading_list_import_path, params: { post_ids: [ posts(:design_post).id ] }, as: :json
    end

    assert_response :unauthorized
  end
end
