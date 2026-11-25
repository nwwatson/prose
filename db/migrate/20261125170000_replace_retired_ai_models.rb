# Moves saved AI model choices off ids their providers have retired (or are about
# to), keeping each on the same provider so the stored API key still applies.
class ReplaceRetiredAiModels < ActiveRecord::Migration[8.1]
  AI_MODEL_REPLACEMENTS = {
    "claude-sonnet-4-5-20250929" => "claude-sonnet-5-5",
    "claude-haiku-4-5-20251001" => "claude-haiku-5-5",
    "claude-opus-4-20250514" => "claude-opus-5-5"
  }.freeze

  IMAGE_MODEL_REPLACEMENTS = {
    "imagen-4.0-generate-001" => "gemini-nano-banana-2.1",
    "imagen-4.0-fast-generate-001" => "gemini-3.1-flash-lite-image",
    "imagen-4.0-ultra-generate-001" => "gemini-3-pro-image",
    "gpt-image-1" => "gpt-image-2.6-sunburst",
    "gpt-image-1-mini" => "gpt-image-2.6-flare",
    "dall-e-3" => "gpt-image-2.6-sunburst"
  }.freeze

  def up
    change_column_default :site_settings, :ai_model, "claude-sonnet-5-5"
    change_column_default :site_settings, :image_model, "gemini-nano-banana-2.1"
    replace_saved_models
  end

  # The old ids no longer work, so saved choices are left on their replacements.
  def down
    change_column_default :site_settings, :ai_model, "claude-sonnet-4-5-20250929"
    change_column_default :site_settings, :image_model, "imagen-4.0-generate-001"
  end

  def replace_saved_models
    replace_values :ai_model, AI_MODEL_REPLACEMENTS
    replace_values :image_model, IMAGE_MODEL_REPLACEMENTS
  end

  private

  def replace_values(column, replacements)
    replacements.each do |retired, replacement|
      execute "UPDATE site_settings SET #{column} = #{connection.quote(replacement)} " \
              "WHERE #{column} = #{connection.quote(retired)}"
    end
  end
end
