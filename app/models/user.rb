class User < ApplicationRecord
  include Authenticatable
  include ApiTokenable
  include PasskeyAuthenticatable
  include IdentityBacked

  has_secure_password

  enum :role, { admin: 0, writer: 1 }

  has_many :sessions, dependent: :destroy
  has_many :posts, dependent: :nullify
  has_many :pages, dependent: :nullify
  has_many :newsletters, dependent: :nullify

  validates :password, password_complexity: true, if: -> { password.present? }

  delegate :name, to: :identity

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

  def default_identity_name
    @pending_display_name || super
  end
end
