class MailingListSubscription < ApplicationRecord
  belongs_to :mailing_list
  belongs_to :subscriber

  validates :subscriber_id, uniqueness: { scope: :mailing_list_id }
end
