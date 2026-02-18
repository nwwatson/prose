class Love < ApplicationRecord
  belongs_to :post, counter_cache: true
  belongs_to :identity

  validates :identity_id, uniqueness: { scope: :post_id }
end
