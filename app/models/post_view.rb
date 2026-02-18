class PostView < ApplicationRecord
  belongs_to :post

  validates :ip_hash, presence: true

  scope :since, ->(date) { where("created_at >= ?", date) }
  scope :for_post, ->(post) { where(post: post) }

  def self.hash_ip(ip_address)
    Digest::SHA256.hexdigest("#{ip_address}-#{Rails.application.secret_key_base.first(16)}")
  end
end
