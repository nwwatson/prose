class SiteSetting < ApplicationRecord
  include Typography
  include Appearance
  include AiConfiguration

  has_one_attached :default_og_image

  validates :site_name, presence: true

  def self.current
    first_or_create!(site_name: "Prose", site_description: "A thoughtfully crafted publication")
  end
end
