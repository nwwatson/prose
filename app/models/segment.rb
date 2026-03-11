class Segment < ApplicationRecord
  include Resolvable

  has_many :newsletters, dependent: :nullify

  validates :name, presence: true
end
