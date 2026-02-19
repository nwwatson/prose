require "test_helper"

class Admin::Ai::MessagesControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_as(:admin)
    @post = posts(:published_post)
    SiteSetting.current.update!(claude_api_key: "test-key")
  end

  test "create creates user message and enqueues job" do
    assert_difference "Message.count", 1 do
      assert_enqueued_with(job: AiResponseJob) do
        post admin_post_ai_messages_path(@post), params: {
          content: "Help me improve this post",
          conversation_type: "chat"
        }, as: :turbo_stream
      end
    end
    assert_response :success
  end

  test "create rejects blank content" do
    post admin_post_ai_messages_path(@post), params: {
      content: "",
      conversation_type: "chat"
    }
    assert_response :unprocessable_entity
  end

  test "create with quick_action creates user message and enqueues job" do
    assert_difference "Message.count", 1 do
      assert_enqueued_with(job: AiResponseJob) do
        post admin_post_ai_messages_path(@post), params: {
          content: "Proofread my post",
          conversation_type: "chat",
          quick_action: "proofread"
        }, as: :turbo_stream
      end
    end
    assert_response :success
  end

  test "redirects when AI not configured" do
    SiteSetting.current.update!(claude_api_key: nil)
    post admin_post_ai_messages_path(@post), params: {
      content: "Hello",
      conversation_type: "chat"
    }
    assert_redirected_to edit_admin_settings_path
  end
end
