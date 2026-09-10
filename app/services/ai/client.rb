module Ai
  module Client
    module_function

    def configure!(settings = SiteSetting.current)
      RubyLLM.configure do |config|
        config.anthropic_api_key = settings.claude_api_key
        config.gemini_api_key = settings.gemini_api_key
        config.openai_api_key = settings.openai_api_key
      end
    end

    def chat(settings = SiteSetting.current)
      configure!(settings)
      RubyLLM.chat(model: settings.ai_model_name)
    end

    def paint(prompt, settings = SiteSetting.current)
      configure!(settings)
      RubyLLM.paint(prompt, model: settings.image_model_name_for_image)
    end
  end
end
