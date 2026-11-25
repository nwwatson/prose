module Subscriber::Authenticatable
  extend ActiveSupport::Concern

  TOKEN_EXPIRY = 15.minutes

  # Sets a fresh sign-in token without saving, so a new subscriber is written once.
  def assign_auth_token
    assign_attributes(
      auth_token: SecureRandom.urlsafe_base64(32),
      auth_token_sent_at: Time.current
    )
  end

  def generate_auth_token!
    assign_auth_token
    save!
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
