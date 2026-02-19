module Admin
  module Ai
    class ConversationsController < BaseController
      def show
        @conversation_type = params[:type] || "chat"
        @chat = Chat.find_or_create_for(
          post: @post,
          user: current_user,
          conversation_type: @conversation_type
        )
        @messages = @chat.messages.where(role: %w[user assistant]).order(:created_at)

        render layout: false if request.xhr? || request.headers["Accept"]&.include?("text/vnd.turbo-stream.html")
      end

      def create
        conversation_type = params[:conversation_type] || "chat"
        @chat = Chat.create!(
          post: @post,
          user: current_user,
          conversation_type: conversation_type
        )
        redirect_to admin_post_ai_conversation_path(@post, type: conversation_type)
      end
    end
  end
end
