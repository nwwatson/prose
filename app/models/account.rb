# frozen_string_literal: true

class Account < ApplicationRecord
  has_many :publications, dependent: :destroy

  validates :name, presence: true, length: { maximum: 100 }
end
