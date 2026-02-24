module Admin
  module Ai
    class FeaturedImagesController < BaseController
      before_action :require_image_ai_configured

      def suggest_prompt
        configure_ruby_llm!

        context = ::Ai::PostContextBuilder.new(@post).build
        prompt = ::Ai::SystemPrompts.image_prompt(context)
        settings = SiteSetting.current

        chat = RubyLLM.chat(model: settings.ai_model_name)
        response = chat.ask(prompt)

        @suggested_prompt = response.content.to_s.strip

        respond_to do |format|
          format.turbo_stream {
            render turbo_stream: turbo_stream.replace(
              "ai-image-modal-content",
              partial: "admin/ai/image_prompt_form",
              locals: { post: @post, suggested_prompt: @suggested_prompt }
            )
          }
          format.html { redirect_to edit_admin_post_path(@post) }
        end
      rescue RubyLLM::Error => e
        respond_to do |format|
          format.turbo_stream {
            render turbo_stream: turbo_stream.replace(
              "ai-image-modal-content",
              partial: "admin/ai/featured_image_error",
              locals: { error: e.message, post: @post }
            )
          }
          format.html { redirect_to edit_admin_post_path(@post), alert: "AI error: #{e.message}" }
        end
      end

      def create
        prompt = params[:prompt].to_s.strip
        return head :unprocessable_entity if prompt.blank?

        GenerateFeaturedImageJob.perform_later(@post.id, prompt, current_user.id)

        respond_to do |format|
          format.turbo_stream {
            render turbo_stream: turbo_stream.replace(
              "ai-image-modal-content",
              partial: "admin/ai/featured_image_loading"
            )
          }
          format.html { redirect_to edit_admin_post_path(@post), notice: t("flash.admin.ai.generating_image") }
        end
      end
    end
  end
end
