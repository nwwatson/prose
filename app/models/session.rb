class Session < ApplicationRecord
  belongs_to :user

  before_create :generate_token
  before_create :set_expiry

  scope :active, -> { where("expires_at > ?", Time.current) }

  def expired?
    expires_at <= Time.current
  end

  private

  def generate_token
    self.token = SecureRandom.urlsafe_base64(32)
  end

  def set_expiry
    self.expires_at ||= 14.days.from_now
  end
end
