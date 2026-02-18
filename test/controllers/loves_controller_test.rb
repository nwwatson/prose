require "test_helper"

class LovesControllerTest < ActionDispatch::IntegrationTest
  test "POST create requires identity" do
    post post_love_path(posts(:published_post))
    assert_redirected_to root_path
  end

  test "POST create creates love as subscriber" do
    sign_in_subscriber(subscribers(:with_token))

    assert_difference "Love.count", 1 do
      post post_love_path(posts(:featured_post))
    end
  end

  test "DELETE destroy removes love" do
    sign_in_subscriber(subscribers(:confirmed))

    assert_difference "Love.count", -1 do
      delete post_love_path(posts(:published_post))
    end
  end

  test "POST create creates love as staff user" do
    sign_in_as(:admin)

    assert_difference "Love.count", 1 do
      post post_love_path(posts(:featured_post))
    end
  end
end
