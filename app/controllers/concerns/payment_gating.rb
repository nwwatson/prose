module PaymentGating
  extend ActiveSupport::Concern

  included do
    helper_method :payments_configured?
  end

  def payments_configured?
    return @payments_configured if defined?(@payments_configured)

    @payments_configured = PaymentService.configured?
  end

  def require_payments_configured(redirect_to: root_path, alert: nil)
    return if payments_configured?

    redirect_to(redirect_to, alert: alert)
  end
end
