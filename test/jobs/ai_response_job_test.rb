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

  test "every quick action has its own system prompt and anything else is a chat" do
    context = "Title: Test\nContent: test content"
    chat_prompt = Ai::SystemPrompts.chat(context)

    Ai::SystemPrompts::QUICK_ACTIONS.each do |action, method_name|
      assert_equal Ai::SystemPrompts.public_send(method_name, context), Ai::SystemPrompts.for(action, context)
      refute_equal chat_prompt, Ai::SystemPrompts.for(action, context)
    end

    assert_equal chat_prompt, Ai::SystemPrompts.for(nil, context)
    assert_equal chat_prompt, Ai::SystemPrompts.for("unknown", context)
  end

  test "batches streamed chunks into few broadcasts without changing the text" do
    chunks = Array.new(100) { |i| "word#{i} " }

    broadcasts = with_const(AiResponseJob, :STREAM_FLUSH_INTERVAL, 60) { run_job_streaming(chunks) }

    assert_operator broadcasts.size, :<=, 5
    assert_equal chunks.join, broadcasts.join
    assert_equal chunks.join, @chat.messages.where(role: "assistant").last.content
  end

  test "flushes as soon as the interval has passed" do
    broadcasts = with_const(AiResponseJob, :STREAM_FLUSH_INTERVAL, 0) { run_job_streaming(%w[one two three]) }

    assert_equal %w[one two three], broadcasts
  end

  test "escapes streamed text so markup split across chunks reaches the view as text" do
    broadcasts = with_const(AiResponseJob, :STREAM_FLUSH_INTERVAL, 60) do
      run_job_streaming([ "<img src=x ", "onerror=alert(1)> & done" ])
    end

    assert_equal [ "&lt;img src=x onerror=alert(1)&gt; &amp; done" ], broadcasts
    assert_equal "<img src=x onerror=alert(1)> & done", @chat.messages.where(role: "assistant").last.content
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

  private

  # Runs the job against a fake LLM that streams +chunks+, returning the HTML of
  # each chunk broadcast.
  def run_job_streaming(chunks)
    fake_chat = Object.new
    fake_chat.define_singleton_method(:with_instructions) { |_| self }
    fake_chat.define_singleton_method(:add_message) { |**| }
    fake_chat.define_singleton_method(:ask) do |_content, &block|
      chunks.each { |content| block.call(Struct.new(:content).new(content)) }
    end

    broadcasts = []
    target = "ai-streaming-content-#{@chat.id}"
    record = ->(*, **options) { broadcasts << options[:html].to_str if options[:target] == target }

    stub_client_chat(fake_chat) do
      with_singleton_stub(Turbo::StreamsChannel, :broadcast_append_to, record) do
        with_singleton_stub(Turbo::StreamsChannel, :broadcast_replace_to, ->(*, **) { }) do
          AiResponseJob.perform_now(@chat.id, "Hello")
        end
      end
    end

    broadcasts
  end
end
