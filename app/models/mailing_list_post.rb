class MailingListPost < ApplicationRecord
  belongs_to :mailing_list
  belongs_to :post

  validates :post_id, uniqueness: { scope: :mailing_list_id }
end
