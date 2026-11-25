class EmailService::Base
  # Hands one newsletter email to the provider and returns once the provider
  # has accepted it. Must raise (EmailService::DeliveryError or the provider's
  # own error) when it was not accepted: SendNewsletterJob records the
  # recipient as delivered as soon as this returns.
  def deliver_newsletter(newsletter, subscriber)
    raise NotImplementedError
  end
end
