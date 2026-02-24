class User < ApplicationRecord
  include Authenticatable
  include ApiTokenable
  include PasskeyAuthenticatable

  has_secure_password

  enum :role, { admin: 0, writer: 1 }

  belongs_to :identity
  has_many :sessions, dependent: :destroy
  has_many :posts, dependent: :nullify
  has_many :pages, dependent: :nullify
  has_many :newsletters, dependent: :nullify

  validates :email, presence: true, uniqueness: { case_sensitive: false }, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :password, password_complexity: true, if: -> { password.present? }

  normalizes :email, with: ->(email) { email.strip.downcase }

  delegate :name, to: :identity

  before_validation :build_identity_if_needed, on: :create

  def display_name
    identity&.name
  end

  def display_name=(value)
    if identity
      identity.name = value
    else
      @pending_display_name = value
    end
  end

  private

  def build_identity_if_needed
    return if identity.present?

    build_identity(name: @pending_display_name || email&.split("@")&.first)
  end
end
