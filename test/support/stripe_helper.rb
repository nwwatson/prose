module StripeHelper
  # Turns paid memberships on. The test transaction rolls the setting back, so
  # there is no need to undo it in a teardown or `ensure`.
  def configure_stripe!(**attrs)
    SiteSetting.current.update!(stripe_secret_key: "sk_test", stripe_publishable_key: "pk_test", **attrs)
  end

  def unconfigure_stripe!
    SiteSetting.current.update!(stripe_secret_key: nil, stripe_publishable_key: nil)
  end
end
