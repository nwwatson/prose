class FediverseLike < ApplicationRecord
  belongs_to :post
  belongs_to :fediverse_actor

  validates :fediverse_actor_id, uniqueness: { scope: :post_id }
end
