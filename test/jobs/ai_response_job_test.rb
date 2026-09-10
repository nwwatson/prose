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

  test "replay_history issues a constant number of messages queries regardless of history size" do
    @chat.messages.create!(role: "assistant", content: "Hi there")
    5.times do |i|
      @chat.messages.create!(role: "user", content: "Message #{i}")
      @chat.messages.create!(role: "assistant", content: "Reply #{i}")
    end
    latest_user_message_id = @chat.messages.where(role: "user").order(:created_at).last.id

    job = AiResponseJob.new
    standalone = Struct.new(:added) do
      def add_message(role:, content:)
        (self.added ||= []) << [ role, content ]
      end
    end.new

    assert_query_count(1, table: "messages") do
      job.send(:replay_history, standalone, @chat, latest_user_message_id)
    end

    assert_equal @chat.messages.count - 1, standalone.added.size
    refute_includes standalone.added.map(&:last), @chat.messages.find(latest_user_message_id).content
  end
end
