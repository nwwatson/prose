# A subscriber's mailing list memberships. New subscribers join every list
# marked "subscribe by default"; after that they pick lists on the email
# preferences page, which writes through `selected_mailing_list_ids=`.
#
# Unsubscribing from everything (`Subscriber#unsubscribe!`) is separate and
# always wins: list rows are kept, but `Subscriber.confirmed` excludes them.
module Subscriber::ListSubscribable
  extend ActiveSupport::Concern

  included do
    has_many :mailing_list_subscriptions, dependent: :delete_all
    has_many :mailing_lists, through: :mailing_list_subscriptions

    scope :subscribed_to, ->(lists) { where(id: MailingListSubscription.where(mailing_list_id: lists.select(:id)).select(:subscriber_id)) }

    after_create :subscribe_to_default_lists
    after_save :sync_selected_mailing_lists, unless: -> { @selected_mailing_list_ids.nil? }
  end

  # Active lists this subscriber receives; inactive lists aren't shown on the
  # preferences form, so they're not part of the selection.
  def selected_mailing_list_ids
    @selected_mailing_list_ids || mailing_list_subscriptions.where(mailing_list_id: MailingList.active.select(:id)).pluck(:mailing_list_id)
  end

  # Replaces the subscriber's active-list subscriptions on save. Subscriptions
  # to inactive lists are left untouched so reactivating a list restores them.
  def selected_mailing_list_ids=(ids)
    @selected_mailing_list_ids = Array(ids).compact_blank.map(&:to_i)
  end

  private

  def subscribe_to_default_lists
    MailingList.subscribed_by_default.find_each { |list| mailing_list_subscriptions.create!(mailing_list: list) }
  end

  def sync_selected_mailing_lists
    active_ids = MailingList.active.ids
    wanted = @selected_mailing_list_ids & active_ids
    @selected_mailing_list_ids = nil

    mailing_list_subscriptions.where(mailing_list_id: active_ids - wanted).delete_all
    (wanted - mailing_list_subscriptions.pluck(:mailing_list_id)).each do |list_id|
      mailing_list_subscriptions.create!(mailing_list_id: list_id)
    end
    mailing_list_subscriptions.reset
  end
end
