module IdentityBacked
  extend ActiveSupport::Concern

  included do
    belongs_to :identity

    validates :email, presence: true, uniqueness: { case_sensitive: false }, format: { with: URI::MailTo::EMAIL_REGEXP }

    normalizes :email, with: ->(email) { email.strip.downcase }

    before_validation :build_identity_if_needed, on: :create
  end

  private

  def default_identity_name
    email&.split("@")&.first
  end

  def build_identity_if_needed
    return if identity.present?

    build_identity(name: default_identity_name)
  end
end
