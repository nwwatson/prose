class Identity < ApplicationRecord
  include Handleable

  has_many :comments, dependent: :destroy
  has_many :loves, dependent: :destroy
  has_one :user, dependent: :nullify
  has_one :subscriber, dependent: :nullify

  validates :name, presence: true
end
