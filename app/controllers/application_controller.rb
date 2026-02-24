class ApplicationController < ActionController::Base
  include SubscriberAuthentication
  include IdentityAuthentication

  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  before_action :set_locale

  private

  def set_locale
    I18n.locale = SiteSetting.current.locale
  end

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes
end
