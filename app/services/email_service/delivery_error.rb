# Raised by an EmailService adapter when the provider did not accept a message,
# so callers never record it as delivered.
class EmailService::DeliveryError < StandardError
  attr_reader :status_code

  def initialize(message = nil, status_code: nil)
    @status_code = status_code
    super(message)
  end
end
