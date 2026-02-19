require "test_helper"

class SiteSetting::AiConfigurationTest < ActiveSupport::TestCase
  setup do
    @setting = SiteSetting.current
  end

  test "ai_configured? returns false when claude_api_key is blank" do
    @setting.update!(claude_api_key: nil)
    assert_not @setting.ai_configured?
  end

  test "ai_configured? returns true when claude_api_key is present" do
    @setting.update!(claude_api_key: "sk-ant-test-key")
    assert @setting.ai_configured?
  end

  # Provider-aware image_ai_configured? tests

  test "image_ai_configured? with gemini model and gemini key" do
    @setting.update!(claude_api_key: "sk-ant-test", gemini_api_key: "AIza-test", image_model: "imagen-4.0-generate-001")
    assert @setting.image_ai_configured?
  end

  test "image_ai_configured? with gemini model but only openai key" do
    @setting.update!(claude_api_key: "sk-ant-test", gemini_api_key: nil, openai_api_key: "sk-test", image_model: "imagen-4.0-generate-001")
    assert_not @setting.image_ai_configured?
  end

  test "image_ai_configured? with openai model and openai key" do
    @setting.update!(claude_api_key: "sk-ant-test", openai_api_key: "sk-test", image_model: "gpt-image-1")
    assert @setting.image_ai_configured?
  end

  test "image_ai_configured? with openai model but only gemini key" do
    @setting.update!(claude_api_key: "sk-ant-test", openai_api_key: nil, gemini_api_key: "AIza-test", image_model: "gpt-image-1")
    assert_not @setting.image_ai_configured?
  end

  test "image_ai_configured? always requires claude_api_key" do
    @setting.update!(claude_api_key: nil, gemini_api_key: "AIza-test", image_model: "imagen-4.0-generate-001")
    assert_not @setting.image_ai_configured?

    @setting.update!(claude_api_key: nil, openai_api_key: "sk-test", image_model: "gpt-image-1")
    assert_not @setting.image_ai_configured?
  end

  # Encryption tests

  test "encrypts claude_api_key" do
    @setting.update!(claude_api_key: "sk-ant-test-key-123")
    raw_value = SiteSetting.connection.select_value(
      "SELECT claude_api_key FROM site_settings WHERE id = #{@setting.id}"
    )
    assert_not_equal "sk-ant-test-key-123", raw_value
    assert_equal "sk-ant-test-key-123", @setting.reload.claude_api_key
  end

  test "encrypts gemini_api_key" do
    @setting.update!(gemini_api_key: "AIza-test-key-456")
    raw_value = SiteSetting.connection.select_value(
      "SELECT gemini_api_key FROM site_settings WHERE id = #{@setting.id}"
    )
    assert_not_equal "AIza-test-key-456", raw_value
    assert_equal "AIza-test-key-456", @setting.reload.gemini_api_key
  end

  test "encrypts openai_api_key" do
    @setting.update!(openai_api_key: "sk-test-key-789")
    raw_value = SiteSetting.connection.select_value(
      "SELECT openai_api_key FROM site_settings WHERE id = #{@setting.id}"
    )
    assert_not_equal "sk-test-key-789", raw_value
    assert_equal "sk-test-key-789", @setting.reload.openai_api_key
  end

  # Validation tests

  test "validates ai_model inclusion" do
    @setting.ai_model = "invalid-model"
    assert_not @setting.valid?
    assert_includes @setting.errors[:ai_model], "is not included in the list"
  end

  test "allows valid ai_models" do
    SiteSetting::AiConfiguration::AI_MODELS.each do |model|
      @setting.ai_model = model
      @setting.valid?
      assert_not_includes @setting.errors[:ai_model], "is not included in the list"
    end
  end

  test "validates image_model inclusion" do
    @setting.image_model = "invalid-image-model"
    assert_not @setting.valid?
    assert_includes @setting.errors[:image_model], "is not included in the list"
  end

  test "allows valid image_models" do
    SiteSetting::AiConfiguration::IMAGE_MODELS.keys.each do |model|
      @setting.image_model = model
      @setting.valid?
      assert_not_includes @setting.errors[:image_model], "is not included in the list"
    end
  end

  test "validates ai_max_tokens range" do
    @setting.ai_max_tokens = 0
    assert_not @setting.valid?

    @setting.ai_max_tokens = 20000
    assert_not @setting.valid?

    @setting.ai_max_tokens = 4096
    @setting.valid?
    assert_empty @setting.errors[:ai_max_tokens]
  end

  # Helper method tests

  test "ai_model_name returns configured model or default" do
    @setting.ai_model = "claude-haiku-4-5-20251001"
    assert_equal "claude-haiku-4-5-20251001", @setting.ai_model_name

    @setting.ai_model = ""
    assert_equal "claude-sonnet-4-5-20250929", @setting.ai_model_name
  end

  test "image_model_name_for_image returns configured model or default" do
    @setting.image_model = "gpt-image-1"
    assert_equal "gpt-image-1", @setting.image_model_name_for_image

    @setting.image_model = ""
    assert_equal "imagen-4.0-generate-001", @setting.image_model_name_for_image
  end

  test "image_model_provider returns provider for configured model" do
    @setting.image_model = "imagen-4.0-generate-001"
    assert_equal :gemini, @setting.image_model_provider

    @setting.image_model = "gpt-image-1"
    assert_equal :openai, @setting.image_model_provider

    @setting.image_model = "dall-e-3"
    assert_equal :openai, @setting.image_model_provider
  end
end
