class ApiToken < ApplicationRecord
  TOKEN_PREFIX = "prose_"
  # How stale `last_used_at` may get before a request from the same IP rewrites it.
  USAGE_TOUCH_INTERVAL = 1.minute

  belongs_to :user

  validates :name, presence: true
  validates :token_digest, presence: true, uniqueness: true
  validates :token_prefix, presence: true

  scope :active, -> { where(revoked_at: nil) }
  # Admins manage every token; writers only their own.
  scope :visible_to, ->(user) { user.admin? ? all : where(user: user) }

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

  # Runs on every API and MCP request, so it writes only when the IP changes or
  # the stored time is stale: SQLite has a single writer.
  def touch_usage!(ip_address:)
    return if last_used_ip == ip_address && last_used_at&.after?(USAGE_TOUCH_INTERVAL.ago)

    update_columns(last_used_at: Time.current, last_used_ip: ip_address)
  end
end
