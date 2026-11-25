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

    # The image model ids are ours (SiteSetting::AiConfiguration::IMAGE_MODELS), so
    # send them straight to their provider. A stored registry can lag behind that
    # list, and RubyLLM resolves some ids to another provider when none is given.
    def paint(prompt, settings = SiteSetting.current)
      configure!(settings)
      RubyLLM.paint(prompt, model: settings.image_model_name_for_image,
                            provider: settings.image_model_provider, assume_model_exists: true)
    end
  end
end
