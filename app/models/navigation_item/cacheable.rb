# Navigation renders on every public page but rarely changes, so each
# location's items are cached (Solid Cache in production) and expired on
# any commit rather than queried per request.
module NavigationItem::Cacheable
  extend ActiveSupport::Concern

  CACHE_VERSION = 1

  included do
    after_commit :expire_navigation_cache
  end

  class_methods do
    def for_location(location)
      Rails.cache.fetch(navigation_cache_key(location)) { where(location: location).ordered.to_a }
    end

    def expire_navigation_cache
      locations.each_key { |location| Rails.cache.delete(navigation_cache_key(location)) }
    end

    private

    def navigation_cache_key(location)
      [ "navigation_items", CACHE_VERSION, location.to_s ]
    end
  end

  private

  def expire_navigation_cache
    self.class.expire_navigation_cache
  end
end
