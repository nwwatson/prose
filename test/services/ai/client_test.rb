require "test_helper"

class Ai::ClientTest < ActiveSupport::TestCase
  setup do
    SiteSetting.current.update!(
      claude_api_key: "claude-key",
      gemini_api_key: "gemini-key",
      openai_api_key: "openai-key"
    )
  end

  test "configure! sets all three provider keys from settings" do
    Ai::Client.configure!(SiteSetting.current)

    config = RubyLLM.config
    assert_equal "claude-key", config.anthropic_api_key
    assert_equal "gemini-key", config.gemini_api_key
    assert_equal "openai-key", config.openai_api_key
  end

  test "chat configures RubyLLM and builds a chat with the configured model" do
    settings = SiteSetting.current

    chat = Ai::Client.chat(settings)

    assert_equal "claude-key", RubyLLM.config.anthropic_api_key
    assert_equal settings.ai_model_name, chat.model.id
  end

  test "paint configures RubyLLM and delegates to RubyLLM.paint with the image model" do
    settings = SiteSetting.current
    image = Object.new
    captured = nil
    fake_paint = ->(prompt, **options) do
      captured = [ prompt, options ]
      image
    end

    result = with_singleton_stub(RubyLLM, :paint, fake_paint) { Ai::Client.paint("a sunset", settings) }

    expected = { model: settings.image_model_name_for_image, provider: settings.image_model_provider, assume_model_exists: true }
    assert_equal [ "a sunset", expected ], captured
    assert_same image, result
    assert_equal "openai-key", RubyLLM.config.openai_api_key
  end
end
