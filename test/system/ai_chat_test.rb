require "application_system_test_case"

class AiChatTest < ApplicationSystemTestCase
  setup do
    SiteSetting.current.update!(claude_api_key: "test-key")
    sign_in_admin
    @post = posts(:published_post)
  end

  test "sending a message appends it to the conversation" do
    open_ai_tab

    find("[data-ai-chat-target='messageInput']").set("Proofread my post")
    find("[data-action='click->ai-chat#submitMessage']").click

    assert_selector "#ai-messages", text: "Proofread my post"
    assert_no_selector "#ai-empty-state"
  end

  test "a quick action sends its prompt" do
    open_ai_tab

    find("[data-quick-action='critique']").click

    assert_selector "#ai-messages", text: "Critique my post"
  end

  private
    def open_ai_tab
      visit edit_admin_post_path(@post)
      find("[data-action='click->editor-drawer#toggle']").click
      assert_selector "[data-ai-chat-target='messageInput']", visible: true
    end
end
