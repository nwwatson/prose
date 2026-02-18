module Subscriber::Authenticatable
  extend ActiveSupport::Concern

  TOKEN_EXPIRY = 15.minutes

  def generate_auth_token!
    update!(
      auth_token: SecureRandom.urlsafe_base64(32),
      auth_token_sent_at: Time.current
    )
    auth_token
  end

  def consume_auth_token!(token)
    return false unless auth_token == token
    return false if auth_token_expired?

    update!(auth_token: nil, auth_token_sent_at: nil)
    confirm!
    true
  end

  def auth_token_expired?
    auth_token_sent_at.blank? || auth_token_sent_at < TOKEN_EXPIRY.ago
  end
end
