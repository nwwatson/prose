module Identity::Profileable
  extend ActiveSupport::Concern

  included do
    has_one_attached :avatar

    validates :website_url, format: { with: URI::DEFAULT_PARSER.make_regexp(%w[http https]), allow_blank: true }
    validates :twitter_handle, format: { with: /\A[a-zA-Z0-9_]{1,15}\z/, allow_blank: true }
    validates :github_handle, format: { with: /\A[a-zA-Z0-9\-]+\z/, allow_blank: true }

    normalizes :twitter_handle, with: ->(handle) { handle.strip.delete_prefix("@") }
    normalizes :github_handle, with: ->(handle) { handle.strip }

    scope :authors, -> { where(id: User.select(:identity_id)) }
    scope :with_handle, -> { where.not(handle: [ nil, "" ]) }
  end

  def bio_html
    MarkdownRenderer.to_html(bio)
  end

  def twitter_url
    "https://x.com/#{twitter_handle}" if twitter_handle.present?
  end

  def github_url
    "https://github.com/#{github_handle}" if github_handle.present?
  end

  def has_social_links?
    website_url.present? || twitter_handle.present? || github_handle.present?
  end

  def has_profile?
    bio.present? || avatar.attached? || has_social_links?
  end
end
