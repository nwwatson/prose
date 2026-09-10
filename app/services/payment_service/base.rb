class PaymentService::Base
  def create_customer(email:, name: nil)
    raise NotImplementedError
  end

  def create_checkout_session(price_id:, customer_email:, success_url:, cancel_url:, customer_id: nil)
    raise NotImplementedError
  end

  def create_portal_session(customer_id:, return_url:)
    raise NotImplementedError
  end

  def cancel_subscription(subscription_id)
    raise NotImplementedError
  end

  def retrieve_subscription(subscription_id)
    raise NotImplementedError
  end

  def create_product(name:, description: nil)
    raise NotImplementedError
  end

  def create_price(product_id:, amount:, currency:, interval:)
    raise NotImplementedError
  end

  def construct_webhook_event(payload:, signature:)
    raise NotImplementedError
  end
end
