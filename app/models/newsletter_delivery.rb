class NewsletterDelivery < ApplicationRecord
  belongs_to :newsletter
  belongs_to :subscriber
end
