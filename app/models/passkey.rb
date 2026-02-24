class Passkey < ApplicationRecord
  belongs_to :user

  validates :credential_id, presence: true, uniqueness: true
  validates :public_key, presence: true
  validates :name, presence: true

  def touch_usage!
    update!(last_used_at: Time.current)
  end
end
