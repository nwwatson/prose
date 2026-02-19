module Ai
  module Configurable
    extend ActiveSupport::Concern

    private

    def configure_ruby_llm!
      settings = SiteSetting.current
      RubyLLM.configure do |config|
        config.anthropic_api_key = settings.claude_api_key
        config.gemini_api_key = settings.gemini_api_key
        config.openai_api_key = settings.openai_api_key
      end
    end

    def require_ai_configured
      unless SiteSetting.current.ai_configured?
        redirect_to edit_admin_settings_path, alert: "Add your API keys in Settings to enable AI features."
      end
    end

    def require_image_ai_configured
      settings = SiteSetting.current
      unless settings.image_ai_configured?
        provider = settings.image_model_provider&.to_s&.titleize || "image"
        redirect_to edit_admin_settings_path,
          alert: "Add your Anthropic and #{provider} API keys in Settings to enable image generation."
      end
    end
  end
end
