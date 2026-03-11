class SubscriberLabeling < ApplicationRecord
  belongs_to :subscriber
  belongs_to :subscriber_label

  validates :subscriber_label_id, uniqueness: { scope: :subscriber_id }
end
