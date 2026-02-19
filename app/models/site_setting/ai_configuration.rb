module SiteSetting::AiConfiguration
  extend ActiveSupport::Concern

  AI_MODELS = %w[
    claude-sonnet-4-5-20250929
    claude-haiku-4-5-20251001
    claude-opus-4-20250514
  ].freeze

  IMAGE_MODELS = {
    "imagen-4.0-generate-001" => :gemini,
    "imagen-4.0-fast-generate-001" => :gemini,
    "imagen-4.0-ultra-generate-001" => :gemini,
    "gpt-image-1" => :openai,
    "gpt-image-1-mini" => :openai,
    "dall-e-3" => :openai
  }.freeze

  included do
    encrypts :claude_api_key, deterministic: false
    encrypts :gemini_api_key, deterministic: false
    encrypts :openai_api_key, deterministic: false

    validates :ai_model, inclusion: { in: AI_MODELS }, allow_blank: true
    validates :ai_max_tokens, numericality: { only_integer: true, greater_than: 0, less_than_or_equal_to: 16384 }, allow_nil: true
    validates :image_model, inclusion: { in: IMAGE_MODELS.keys }, allow_blank: true
  end

  def ai_configured?
    claude_api_key.present?
  end

  def image_ai_configured?
    return false unless ai_configured?

    case image_model_provider
    when :gemini then gemini_api_key.present?
    when :openai then openai_api_key.present?
    else false
    end
  end

  def ai_model_name
    ai_model.presence || AI_MODELS.first
  end

  def image_model_name_for_image
    image_model.presence || IMAGE_MODELS.keys.first
  end

  def image_model_provider
    IMAGE_MODELS[image_model_name_for_image]
  end
end
