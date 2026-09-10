module PaymentService
  def self.provider
    settings = SiteSetting.current
    PaymentService::Stripe.new(
      secret_key: settings.stripe_secret_key,
      publishable_key: settings.stripe_publishable_key,
      webhook_secret: settings.stripe_webhook_secret
    )
  end

  def self.configured?
    SiteSetting.current.payments_configured?
  end
end
