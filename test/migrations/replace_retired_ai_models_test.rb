require "test_helper"
require Rails.root.join("db/migrate/20261125170000_replace_retired_ai_models").to_s

class ReplaceRetiredAiModelsTest < ActiveSupport::TestCase
  setup do
    @setting = SiteSetting.current
    @migration = ReplaceRetiredAiModels.new
    @migration.verbose = false
  end

  test "moves every retired id to a model that is offered" do
    ReplaceRetiredAiModels::AI_MODEL_REPLACEMENTS.each do |retired, replacement|
      assert_includes SiteSetting::AiConfiguration::AI_MODELS, replacement
      assert_replaced :ai_model, retired, replacement
    end

    ReplaceRetiredAiModels::IMAGE_MODEL_REPLACEMENTS.each do |retired, replacement|
      assert_includes SiteSetting::AiConfiguration::IMAGE_MODELS.keys, replacement
      assert_replaced :image_model, retired, replacement
    end
  end

  test "keeps image models on the same provider" do
    ReplaceRetiredAiModels::IMAGE_MODEL_REPLACEMENTS.each do |retired, replacement|
      provider = retired.start_with?("imagen") ? :gemini : :openai
      assert_equal provider, SiteSetting::AiConfiguration::IMAGE_MODELS[replacement]
    end
  end

  test "leaves blank choices alone" do
    @setting.update_columns(ai_model: nil, image_model: "")

    @migration.replace_saved_models

    @setting.reload
    assert_nil @setting.ai_model
    assert_equal "", @setting.image_model
  end

  private

  def assert_replaced(column, retired, replacement)
    @setting.update_columns(column => retired)

    @migration.replace_saved_models

    assert_equal replacement, @setting.reload[column]
    assert @setting.valid?
  end
end
