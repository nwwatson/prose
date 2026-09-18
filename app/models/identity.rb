class Identity < ApplicationRecord
  include Handleable
  include Profileable
  include ReadingListable

  has_many :comments, dependent: :destroy
  has_many :loves, dependent: :destroy
  has_one :user, dependent: :nullify
  has_one :subscriber, dependent: :nullify
  has_one :fediverse_actor, dependent: :nullify

  validates :name, presence: true
end
