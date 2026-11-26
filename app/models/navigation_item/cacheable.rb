# Navigation renders on every public page, so all locations are loaded with one
# query and memoized on Current for the rest of the request. Nothing is kept
# between requests, so there is nothing to expire.
module NavigationItem::Cacheable
  extend ActiveSupport::Concern

  class_methods do
    def for_location(location)
      Current.navigation_items ||= ordered.to_a.group_by(&:location)
      Current.navigation_items.fetch(location.to_s, [])
    end
  end
end
