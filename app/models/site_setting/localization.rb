module SiteSetting::Localization
  extend ActiveSupport::Concern

  SUPPORTED_LOCALES = {
    "en" => "English",
    "es" => "Español"
  }.freeze

  included do
    validates :locale, inclusion: { in: SUPPORTED_LOCALES.keys }
  end

  def locale_name
    SUPPORTED_LOCALES[locale] || SUPPORTED_LOCALES["en"]
  end
end
