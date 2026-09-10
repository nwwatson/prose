module SiteSetting::MaskedSecrets
  extend ActiveSupport::Concern

  MASK = "•" * 8
  SECRET_ATTRIBUTES = %w[
    claude_api_key gemini_api_key openai_api_key
    stripe_secret_key stripe_publishable_key stripe_webhook_secret
    sendgrid_api_key
  ].freeze

  # Assigns attrs, dropping any SECRET_ATTRIBUTES whose value is still the
  # placeholder mask (i.e. the admin didn't touch that field) so the stored
  # key isn't overwritten. A blank value still clears the key.
  def assign_attributes_ignoring_mask(attrs)
    filtered = attrs.to_h.reject { |key, value| SECRET_ATTRIBUTES.include?(key.to_s) && value == MASK }
    assign_attributes(filtered)
  end

  def masked_value_for(attribute)
    self[attribute].present? ? MASK : ""
  end
end
