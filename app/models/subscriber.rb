class Subscriber < ApplicationRecord
  include Authenticatable
  include Billable
  include IdentityBacked

  belongs_to :source_post, class_name: "Post", optional: true
  has_many :loves, through: :identity
  has_many :comments, through: :identity
  has_many :subscriber_labelings, dependent: :destroy
  has_many :subscriber_labels, through: :subscriber_labelings
  has_many :newsletter_deliveries, dependent: :destroy

  delegate :handle, to: :identity, allow_nil: true

  scope :confirmed, -> { where.not(confirmed_at: nil).where(unsubscribed_at: nil) }
  scope :active, -> { where(unsubscribed_at: nil) }

  def self.subscribe_or_sign_in!(email:, source_post_id: nil)
    subscriber = find_or_initialize_by(email: email)
    new_subscriber = subscriber.new_record?

    if new_subscriber
      subscriber.source_post_id = source_post_id if source_post_id.present?
      subscriber.save!
      subscriber.generate_auth_token!
      SubscriberMailer.confirmation(subscriber).deliver_later
    else
      subscriber.generate_auth_token!
      SubscriberMailer.magic_link(subscriber).deliver_later
    end

    WebhookDispatcher.deliver("subscriber.created", Webhooks::SubscriberSerializer.call(subscriber)) if new_subscriber

    subscriber
  end

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
    return if unsubscribed?

    update!(unsubscribed_at: Time.current)
    WebhookDispatcher.deliver("subscriber.deleted", Webhooks::SubscriberSerializer.call(self))
  end

  def resubscribe!
    update!(unsubscribed_at: nil)
  end
end
