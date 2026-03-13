class PaymentService::Stripe
  def initialize(secret_key:, publishable_key: nil)
    @secret_key = secret_key
    @publishable_key = publishable_key
  end

  def create_customer(email:, name: nil)
    client.customers.create({ email: email, name: name })
  end

  def create_checkout_session(price_id:, customer_email:, success_url:, cancel_url:, customer_id: nil)
    params = {
      mode: "subscription",
      line_items: [ { price: price_id, quantity: 1 } ],
      success_url: success_url,
      cancel_url: cancel_url
    }
    params[:customer] = customer_id if customer_id.present?
    params[:customer_email] = customer_email if customer_id.blank?

    client.checkout.sessions.create(params)
  end

  def create_portal_session(customer_id:, return_url:)
    client.billing_portal.sessions.create({
      customer: customer_id,
      return_url: return_url
    })
  end

  def cancel_subscription(subscription_id)
    client.subscriptions.cancel(subscription_id)
  end

  def retrieve_subscription(subscription_id)
    client.subscriptions.retrieve(subscription_id)
  end

  def create_product(name:, description: nil)
    params = { name: name }
    params[:description] = description if description.present?
    client.products.create(params)
  end

  def create_price(product_id:, amount:, currency:, interval:)
    client.prices.create({
      product: product_id,
      unit_amount: amount,
      currency: currency,
      recurring: { interval: interval }
    })
  end

  def construct_webhook_event(payload:, signature:)
    webhook_secret = SiteSetting.current.stripe_webhook_secret
    ::Stripe::Webhook.construct_event(payload, signature, webhook_secret)
  end

  private

  def client
    @client ||= ::Stripe::StripeClient.new(@secret_key)
  end
end
