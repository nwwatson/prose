class ApiToken < ApplicationRecord
  TOKEN_PREFIX = "prose_"

  belongs_to :user

  validates :name, presence: true
  validates :token_digest, presence: true, uniqueness: true
  validates :token_prefix, presence: true

  scope :active, -> { where(revoked_at: nil) }

  def self.generate_for(user, name:)
    raw_token = TOKEN_PREFIX + SecureRandom.hex(32)
    record = create!(
      user: user,
      name: name,
      token_digest: Digest::SHA256.hexdigest(raw_token),
      token_prefix: raw_token.first(12)
    )
    [ record, raw_token ]
  end

  def self.find_by_raw_token(raw_token)
    return nil unless raw_token.present?

    digest = Digest::SHA256.hexdigest(raw_token)
    active.find_by(token_digest: digest)
  end

  def revoke!
    update!(revoked_at: Time.current)
  end

  def revoked?
    revoked_at.present?
  end

  def touch_usage!(ip_address:)
    update!(last_used_at: Time.current, last_used_ip: ip_address)
  end
end
