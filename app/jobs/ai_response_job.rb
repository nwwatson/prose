class AiResponseJob < ApplicationJob
  queue_as :default

  def perform(chat_id, user_content, quick_action: nil, title_override: nil, subtitle_override: nil, content_override: nil)
    chat_record = Chat.find(chat_id)
    configure_ruby_llm!

    context = build_context(chat_record, title_override, subtitle_override, content_override)
    system_prompt = resolve_system_prompt(quick_action, context)
    settings = SiteSetting.current

    # Broadcast streaming placeholder
    Turbo::StreamsChannel.broadcast_append_to(
      "chat_#{chat_record.id}",
      target: "ai-messages",
      partial: "admin/ai/messages/assistant_streaming",
      locals: { chat: chat_record }
    )

    # Use a standalone RubyLLM chat for the LLM call so the system prompt
    # and a duplicate user message are never persisted to the database.
    standalone = RubyLLM.chat(model: settings.ai_model_name)
    standalone.with_instructions(system_prompt)

    # Replay conversation history so the LLM has context for follow-up messages
    chat_record.messages.where(role: %w[user assistant]).order(:created_at).find_each do |msg|
      # Skip the latest user message — we'll pass it to `ask` below
      next if msg.role == "user" && msg.content == user_content && msg == chat_record.messages.where(role: "user").order(:created_at).last

      standalone.add_message(role: msg.role.to_sym, content: msg.content)
    end

    full_content = +""
    standalone.ask(user_content) do |chunk|
      if chunk.content.present?
        full_content << chunk.content
        Turbo::StreamsChannel.broadcast_append_to(
          "chat_#{chat_record.id}",
          target: "ai-streaming-content-#{chat_record.id}",
          html: chunk.content
        )
      end
    end

    # Persist only the assistant message
    assistant_message = chat_record.messages.create!(role: "assistant", content: full_content)

    Turbo::StreamsChannel.broadcast_replace_to(
      "chat_#{chat_record.id}",
      target: "ai-streaming-message-#{chat_record.id}",
      partial: "admin/ai/messages/message",
      locals: { message: assistant_message }
    )
  rescue RubyLLM::Error => e
    Turbo::StreamsChannel.broadcast_replace_to(
      "chat_#{chat_record.id}",
      target: "ai-streaming-message-#{chat_record.id}",
      html: "<div class=\"rounded-lg bg-red-50 p-3 text-sm text-red-700\">AI error: #{ERB::Util.html_escape(e.message)}</div>"
    )
  end

  private

  def configure_ruby_llm!
    settings = SiteSetting.current
    RubyLLM.configure do |config|
      config.anthropic_api_key = settings.claude_api_key
      config.gemini_api_key = settings.gemini_api_key
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

  def resolve_system_prompt(quick_action, context)
    case quick_action
    when "proofread" then ::Ai::SystemPrompts.proofread(context)
    when "critique" then ::Ai::SystemPrompts.critique(context)
    when "brainstorm" then ::Ai::SystemPrompts.brainstorm(context)
    when "seo" then ::Ai::SystemPrompts.seo(context)
    when "social" then ::Ai::SystemPrompts.social_media_chat(context)
    when "image_prompt" then ::Ai::SystemPrompts.image_prompt(context)
    else ::Ai::SystemPrompts.chat(context)
    end
  end
end
