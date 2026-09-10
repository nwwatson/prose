class SiteSetting < ApplicationRecord
  include Typography
  include Appearance
  include DarkTheme
  include AiConfiguration
  include EmailConfiguration
  include EmailBranding
  include Localization
  include Crawlers
  include PaymentConfiguration

  has_one_attached :default_og_image

  validates :site_name, presence: true

  after_commit { Current.site_setting = nil }

  def self.current
    Current.site_setting ||= first_or_create!(site_name: "Prose", site_description: "A thoughtfully crafted publication")
  end
end
