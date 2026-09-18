# A remote ActivityPub actor (e.g. a Mastodon account) this site has seen —
# cached so inbox signatures can be verified without refetching the key, and
# so followers can be delivered to. `followed_at` is set while it follows us.
class FediverseActor < ApplicationRecord
  STALE_AFTER = 1.day

  belongs_to :identity, optional: true
  has_many :fediverse_likes, dependent: :destroy

  validates :uri, presence: true, uniqueness: true

  scope :followers, -> { where.not(followed_at: nil) }

  def self.follower_inboxes
    followers.pluck(:shared_inbox_url, :inbox_url).filter_map { |shared, inbox| shared.presence || inbox.presence }.uniq
  end

  def self.unfollow_inbox!(inbox_url)
    followers.where(inbox_url: inbox_url).or(followers.where(shared_inbox_url: inbox_url)).update_all(followed_at: nil)
  end

  def follower?
    followed_at.present?
  end

  def follow!
    update!(followed_at: Time.current) unless follower?
  end

  def unfollow!
    update!(followed_at: nil) if follower?
  end

  def stale?
    fetched_at.nil? || fetched_at < STALE_AFTER.ago
  end

  def domain
    URI.parse(uri).host
  rescue URI::InvalidURIError
    nil
  end

  def handle
    username.present? ? "@#{username}@#{domain}" : uri
  end

  def display_name
    name.presence || username.presence || handle
  end

  # Remote repliers comment through an Identity like everyone else, so replies
  # reuse the existing comment threading and moderation.
  def ensure_identity!
    return identity if identity

    transaction do
      website = profile_url.to_s.match?(%r{\Ahttps?://}) ? profile_url : nil
      update!(identity: Identity.create!(name: display_name.truncate(100), website_url: website))
    end
    identity
  end
end
