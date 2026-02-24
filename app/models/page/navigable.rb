module Page::Navigable
  extend ActiveSupport::Concern

  included do
    scope :navigation, -> { live.where(show_in_navigation: true).order(:position, :title) }
  end
end
