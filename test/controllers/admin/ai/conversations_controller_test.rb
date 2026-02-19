require "test_helper"

class Admin::Ai::ConversationsControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_as(:admin)
    @post = posts(:published_post)
  end

  test "show redirects when AI not configured" do
    SiteSetting.current.update!(claude_api_key: nil)
    get admin_post_ai_conversation_path(@post)
    assert_redirected_to edit_admin_settings_path
  end

  test "show finds or creates chat" do
    SiteSetting.current.update!(claude_api_key: "test-key")
    assert_difference "Chat.count", 1 do
      get admin_post_ai_conversation_path(@post)
    end
    assert_response :success
  end

  test "show uses conversation type param" do
    SiteSetting.current.update!(claude_api_key: "test-key")
    get admin_post_ai_conversation_path(@post, type: "seo")
    assert_response :success
    assert Chat.exists?(post: @post, conversation_type: "seo")
  end

  test "create starts new conversation" do
    SiteSetting.current.update!(claude_api_key: "test-key")
    assert_difference "Chat.count", 1 do
      post admin_post_ai_conversation_path(@post), params: { conversation_type: "chat" }
    end
    assert_redirected_to admin_post_ai_conversation_path(@post, type: "chat")
  end

  test "requires authentication" do
    delete admin_session_path
    get admin_post_ai_conversation_path(@post)
    assert_redirected_to new_admin_session_path
  end
end
