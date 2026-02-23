class Subscriber < ApplicationRecord
  include Authenticatable

  belongs_to :identity
  belongs_to :source_post, class_name: "Post", optional: true
  has_many :loves, through: :identity
  has_many :comments, through: :identity
  has_many :newsletter_deliveries, dependent: :destroy

  validates :email, presence: true, uniqueness: { case_sensitive: false }, format: { with: URI::MailTo::EMAIL_REGEXP }

  normalizes :email, with: ->(email) { email.strip.downcase }

  delegate :handle, to: :identity, allow_nil: true

  before_validation :build_identity_if_needed, on: :create

  scope :confirmed, -> { where.not(confirmed_at: nil).where(unsubscribed_at: nil) }
  scope :active, -> { where(unsubscribed_at: nil) }

  def confirmed?
    confirmed_at.present?
  end

  def confirm!
    update!(confirmed_at: Time.current) unless confirmed?
  end

  def unsubscribed?
    unsubscribed_at.present?
  end

  def unsubscribe!
    update!(unsubscribed_at: Time.current) unless unsubscribed?
  end

  def resubscribe!
    update!(unsubscribed_at: nil)
  end

  private

  def build_identity_if_needed
    return if identity.present?

    build_identity(name: email&.split("@")&.first)
  end
end
