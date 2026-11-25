module SiteSetting::AiConfiguration
  extend ActiveSupport::Concern

  # The first entry of each list is the default. When removing an id, add a data
  # migration that moves saved settings off it, or they fail validation.
  AI_MODELS = %w[
    claude-sonnet-5-5
    claude-haiku-5-5
    claude-opus-5-5
  ].freeze

  IMAGE_MODELS = {
    "gemini-nano-banana-2.1" => :gemini,
    "gemini-3.1-flash-lite-image" => :gemini,
    "gemini-3-pro-image" => :gemini,
    "gpt-image-2.6-sunburst" => :openai,
    "gpt-image-2.6-flare" => :openai
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
