module User::Authenticatable
  extend ActiveSupport::Concern

  class_methods do
    def authenticate_by_email_and_password(email, password)
      user = find_by(email: email.to_s.strip.downcase)
      user&.authenticate(password)
    end
  end

  def create_session!(ip_address: nil, user_agent: nil)
    sessions.create!(
      ip_address: ip_address,
      user_agent: user_agent&.truncate(500)
    )
  end
end
