# Infers which social network a link points at from its URL, so footer
# social links can render the matching icon without an explicit "platform"
# field. Unknown hosts fall back to :website (a generic globe icon).
module NavigationItem::SocialPlatform
  extend ActiveSupport::Concern

  PLATFORM_HOSTS = {
    x: %w[x.com twitter.com],
    github: %w[github.com],
    linkedin: %w[linkedin.com],
    bluesky: %w[bsky.app],
    youtube: %w[youtube.com youtu.be],
    instagram: %w[instagram.com],
    facebook: %w[facebook.com],
    threads: %w[threads.net threads.com],
    mastodon: %w[mastodon.social mastodon.online fosstodon.org hachyderm.io]
  }.freeze

  PLATFORMS = (PLATFORM_HOSTS.keys + %i[rss website]).freeze

  def social_platform
    uri = URI.parse(url)
    host = uri.host.to_s.downcase.delete_prefix("www.")

    PLATFORM_HOSTS.find { |_, hosts| hosts.any? { |h| host == h || host.end_with?(".#{h}") } }&.first ||
      (:rss if uri.path.to_s.match?(%r{/(feed|rss)(\.xml)?\z}i)) ||
      # Mastodon runs on thousands of self-hosted instances; "/@user" is its profile URL shape.
      (:mastodon if uri.path.to_s.match?(%r{\A/@[\w.]+\z})) ||
      :website
  rescue URI::InvalidURIError
    :website
  end
end
