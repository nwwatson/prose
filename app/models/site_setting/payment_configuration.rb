module SiteSetting::PaymentConfiguration
  extend ActiveSupport::Concern

  SUPPORTED_CURRENCIES = {
    "usd" => "USD ($)",
    "eur" => "EUR (\u20AC)",
    "gbp" => "GBP (\u00A3)",
    "cad" => "CAD ($)",
    "aud" => "AUD ($)"
  }.freeze

  included do
    encrypts :stripe_secret_key, deterministic: false
    encrypts :stripe_publishable_key, deterministic: false
    encrypts :stripe_webhook_secret, deterministic: false

    validates :payments_currency, inclusion: { in: SUPPORTED_CURRENCIES.keys }, allow_blank: true
  end

  def payments_configured?
    stripe_secret_key.present? && stripe_publishable_key.present?
  end

  def currency_symbol
    case payments_currency
    when "eur" then "\u20AC"
    when "gbp" then "\u00A3"
    else "$"
    end
  end
end
