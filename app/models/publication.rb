# frozen_string_literal: true

class Publication < ApplicationRecord
  include Sluggable

  belongs_to :account
  has_many :posts, dependent: :destroy

  has_one_attached :favicon
  has_one_attached :logo
  has_one_attached :header_image

  validates :slug, uniqueness: true
  validates :name, presence: true, length: { maximum: 100 }
  validates :tagline, length: { maximum: 200 }
  validates :description, length: { maximum: 2000 }
  validates :custom_domain, uniqueness: { allow_blank: true }, format: {
    with: /\A[a-z0-9]+([\-\.]{1}[a-z0-9]+)*\.[a-z]{2,}\z/i,
    message: "must be a valid domain",
    allow_blank: true
  }
  validates :language, inclusion: { in: %w[en es fr de pt it] }
  validates :timezone, inclusion: { in: ActiveSupport::TimeZone.all.map(&:name) }

  scope :active, -> { where(active: true) }
  scope :with_custom_domain, -> { where.not(custom_domain: [ nil, "" ]) }

  # Settings stored as JSON
  serialize :settings, coder: JSON
  serialize :social_links, coder: JSON

  after_initialize :set_default_settings

  def slug_source
    name
  end

  def primary_domain
    custom_domain.presence || default_subdomain
  end

  def default_subdomain
    "#{slug}.prose.local"
  end

  def social_link(platform)
    (social_links || {})[platform.to_s]
  end

  def setting(key)
    (settings || {})[key.to_s]
  end

  def update_setting(key, value)
    self.settings ||= {}
    self.settings[key.to_s] = value
    save
  end

  private

  def set_default_settings
    self.settings ||= {
      "allow_comments" => true,
      "require_subscription" => false,
      "show_author_bio" => true,
      "email_footer" => "",
      "analytics_code" => ""
    }

    self.social_links ||= {}
  end

  class << self
    def slug_scope
      nil
    end
  end
end
