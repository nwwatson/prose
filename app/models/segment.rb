class Segment < ApplicationRecord
  include Resolvable
  include CriteriaBuilder

  has_many :newsletters, dependent: :nullify

  validates :name, presence: true
end
