module SiteSetting::EmailConfiguration
  extend ActiveSupport::Concern

  EMAIL_PROVIDERS = {
    "smtp" => "SMTP (Default)",
    "sendgrid" => "SendGrid"
  }.freeze

  included do
    encrypts :sendgrid_api_key, deterministic: false

    validates :email_provider, inclusion: { in: EMAIL_PROVIDERS.keys }, allow_blank: true
  end

  def email_configured?
    case email_provider
    when "sendgrid" then sendgrid_api_key.present?
    else true
    end
  end

  def email_provider_name
    EMAIL_PROVIDERS[email_provider] || EMAIL_PROVIDERS["smtp"]
  end

  def sendgrid?
    email_provider == "sendgrid" && sendgrid_api_key.present?
  end
end
