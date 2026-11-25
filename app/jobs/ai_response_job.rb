class AiResponseJob < ApplicationJob
  queue_as :default

  # Streamed chunks are buffered and broadcast together, because every broadcast
  # is a render plus a Solid Cable insert on SQLite. A chunk that arrives once
  # either limit is reached flushes the buffer.
  STREAM_FLUSH_INTERVAL = 0.075 # seconds
  STREAM_FLUSH_SIZE = 200 # characters

  def perform(chat_id, user_content, quick_action: nil, title_override: nil, subtitle_override: nil, content_override: nil)
    chat_record = Chat.find(chat_id)
    settings = SiteSetting.current

    context = build_context(chat_record, title_override, subtitle_override, content_override)
    system_prompt = ::Ai::SystemPrompts.for(quick_action, context)

    # Broadcast streaming placeholder
    Turbo::StreamsChannel.broadcast_append_to(
      "chat_#{chat_record.id}",
      target: "ai-messages",
      partial: "admin/ai/messages/assistant_streaming",
      locals: { chat: chat_record }
    )

    # Use a standalone RubyLLM chat for the LLM call so the system prompt
    # and a duplicate user message are never persisted to the database.
    standalone = ::Ai::Client.chat(settings)
    standalone.with_instructions(system_prompt)

    # Replay conversation history so the LLM has context for follow-up messages
    latest_user_message_id = chat_record.messages.where(role: "user").order(:created_at).last&.id
    replay_history(standalone, chat_record, latest_user_message_id)

    full_content = stream_response(standalone, user_content, chat_record)

    # Persist only the assistant message
    assistant_message = chat_record.messages.create!(role: "assistant", content: full_content)

    Turbo::StreamsChannel.broadcast_replace_to(
      "chat_#{chat_record.id}",
      target: "ai-streaming-message-#{chat_record.id}",
      partial: "admin/ai/messages/message",
      locals: { message: assistant_message }
    )
  rescue RubyLLM::Error, RubyLLM::ModelNotFoundError => e
    Turbo::StreamsChannel.broadcast_replace_to(
      "chat_#{chat_record.id}",
      target: "ai-streaming-message-#{chat_record.id}",
      html: "<div class=\"rounded-lg bg-red-50 p-3 text-sm text-red-700\">AI error: #{ERB::Util.html_escape(e.message)}</div>"
    )
  end

  private

  # Broadcasts the reply as it streams in and returns the whole text.
  def stream_response(standalone, user_content, chat_record)
    full_content = +""
    buffer = +""
    flushed_at = monotonic_now

    standalone.ask(user_content) do |chunk|
      next if chunk.content.blank?

      full_content << chunk.content
      buffer << chunk.content
      next if buffer.length < STREAM_FLUSH_SIZE && monotonic_now - flushed_at < STREAM_FLUSH_INTERVAL

      broadcast_chunk(chat_record, buffer)
      buffer = +""
      flushed_at = monotonic_now
    end

    broadcast_chunk(chat_record, buffer) if buffer.present?
    full_content
  end

  # Turbo inserts +html+ as markup, so the model's text is escaped: the
  # streaming view reads it back through textContent and renders the Markdown.
  def broadcast_chunk(chat_record, text)
    Turbo::StreamsChannel.broadcast_append_to(
      "chat_#{chat_record.id}",
      target: "ai-streaming-content-#{chat_record.id}",
      html: ERB::Util.html_escape(text)
    )
  end

  def monotonic_now
    Process.clock_gettime(Process::CLOCK_MONOTONIC)
  end

  def replay_history(standalone, chat_record, latest_user_message_id)
    chat_record.messages.where(role: %w[user assistant]).order(:created_at).find_each do |msg|
      # Skip the latest user message — we'll pass it to `ask` below
      next if msg.role == "user" && msg.id == latest_user_message_id

      standalone.add_message(role: msg.role.to_sym, content: msg.content)
    end
  end

  def build_context(chat_record, title_override, subtitle_override, content_override)
    builder = ::Ai::PostContextBuilder.new(chat_record.post)
    if title_override.present? || subtitle_override.present? || content_override.present?
      builder.build_with_overrides(
        title: title_override,
        subtitle: subtitle_override,
        content: content_override
      )
    else
      builder.build
    end
  end
end
