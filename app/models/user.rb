class User < ApplicationRecord
  has_secure_password

  has_many :accounts, dependent: :destroy
  has_many :publications, through: :accounts

  validates :email, presence: true, uniqueness: { case_sensitive: false }
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :name, presence: true

  before_save :downcase_email
  before_create :generate_confirmation_token

  scope :confirmed, -> { where.not(confirmed_at: nil) }
  scope :unconfirmed, -> { where(confirmed_at: nil) }

  def confirmed?
    confirmed_at.present?
  end

  def confirm!
    update!(confirmed_at: Time.current, confirmation_token: nil)
  end

  def generate_confirmation_token
    self.confirmation_token = SecureRandom.urlsafe_base64
  end

  def generate_reset_password_token
    self.reset_password_token = SecureRandom.urlsafe_base64
    self.reset_password_sent_at = Time.current
    save!
  end

  def reset_password_token_valid?
    reset_password_sent_at && reset_password_sent_at > 2.hours.ago
  end

  def generate_remember_token
    self.remember_token = SecureRandom.urlsafe_base64
    save!
  end

  def clear_remember_token
    update!(remember_token: nil)
  end

  def account_locked?
    locked_at.present?
  end

  def lock_account!
    update!(locked_at: Time.current)
  end

  def unlock_account!
    update!(locked_at: nil, failed_attempts: 0)
  end

  def increment_failed_attempts!
    self.failed_attempts += 1
    lock_account! if failed_attempts >= 5
    save!
  end

  def reset_failed_attempts!
    update!(failed_attempts: 0)
  end

  def track_sign_in!(request)
    self.last_sign_in_at = current_sign_in_at
    self.current_sign_in_at = Time.current
    self.sign_in_count += 1
    reset_failed_attempts!
    save!
  end

  private

  def downcase_email
    self.email = email.downcase if email
  end
end
