require "test_helper"

class AiResponseJobTest < ActiveSupport::TestCase
  setup do
    @post = posts(:published_post)
    @user = users(:admin)
    SiteSetting.current.update!(claude_api_key: "test-key")
    @chat = Chat.create!(post: @post, user: @user, conversation_type: "chat")
    @chat.messages.create!(role: "user", content: "Hello")
  end

  test "can be instantiated" do
    job = AiResponseJob.new
    assert_instance_of AiResponseJob, job
  end

  test "resolves system prompt for quick actions" do
    job = AiResponseJob.new
    context = "Title: Test\nContent: test content"

    %w[proofread critique brainstorm seo social image_prompt].each do |action|
      prompt = job.send(:resolve_system_prompt, action, context)
      assert prompt.present?, "Expected prompt for #{action} to be present"
    end

    prompt = job.send(:resolve_system_prompt, nil, context)
    assert prompt.present?
  end

  test "builds context from post" do
    job = AiResponseJob.new
    context = job.send(:build_context, @chat, nil, nil, nil)
    assert_includes context, @post.title
  end

  test "builds context with overrides" do
    job = AiResponseJob.new
    context = job.send(:build_context, @chat, "Custom Title", "Custom Subtitle", nil)
    assert_includes context, "Custom Title"
    assert_includes context, "Custom Subtitle"
  end
end
