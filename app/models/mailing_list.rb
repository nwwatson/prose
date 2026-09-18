# A subscribable list of emails ("newsletter" in the public UI). Subscribers
# choose which lists they receive on the email preferences page; posts are
# emailed to the lists chosen in the editor, and campaigns can target one list.
# Not to be confused with `Newsletter`, which is a one-off email campaign.
class MailingList < ApplicationRecord
  include Sluggable

  has_many :mailing_list_subscriptions, dependent: :delete_all
  has_many :subscribers, through: :mailing_list_subscriptions
  has_many :mailing_list_posts, dependent: :delete_all
  has_many :posts, through: :mailing_list_posts
  has_many :newsletters, dependent: :nullify

  validates :name, presence: true, uniqueness: { case_sensitive: false }, length: { maximum: 100 }
  validates :frequency, length: { maximum: 50 }

  slugged_from :name

  scope :active, -> { where(active: true) }
  scope :ordered, -> { order(:name) }
  scope :subscribed_by_default, -> { active.where(subscribe_by_default: true) }

  # Confirmed, not globally unsubscribed subscribers of this list.
  def recipients
    Subscriber.confirmed.where(id: mailing_list_subscriptions.select(:subscriber_id))
  end

  def self.subscriber_counts
    MailingListSubscription.where(subscriber_id: Subscriber.confirmed.select(:id)).group(:mailing_list_id).count
  end
end
