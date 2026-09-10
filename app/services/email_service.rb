module EmailService
  def self.provider
    settings = SiteSetting.current

    case settings.email_provider
    when "sendgrid"
      EmailService::Sendgrid.new(api_key: settings.sendgrid_api_key)
    else
      EmailService::Smtp.new
    end
  end

  def self.configured?
    SiteSetting.current.email_configured?
  end

  def self.from_address
    ENV.fetch("SMTP_FROM", "noreply@example.com")
  end
end
