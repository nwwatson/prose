module Admin
  module Ai
    class MessagesController < BaseController
      def create
        @conversation_type = params[:conversation_type] || "chat"
        @quick_action = params[:quick_action]
        @chat = Chat.find_or_create_for(
          post: @post,
          user: current_user,
          conversation_type: @conversation_type
        )

        content = params[:content].to_s.strip
        return head :unprocessable_entity if content.blank?

        # Create the user message
        @message = @chat.messages.create!(role: "user", content: content)

        # Enqueue the AI response job
        AiResponseJob.perform_later(
          @chat.id,
          content,
          quick_action: @quick_action,
          title_override: params[:title],
          subtitle_override: params[:subtitle],
          content_override: params[:post_content]
        )

        respond_to do |format|
          format.turbo_stream
          format.html { redirect_to admin_post_ai_conversation_path(@post, type: @conversation_type) }
        end
      end
    end
  end
end
