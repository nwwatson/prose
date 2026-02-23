module SiteSetting::EmailBranding
  extend ActiveSupport::Concern

  EMAIL_TEMPLATES = {
    "minimal" => { name: "Minimal", description: "Clean, text-focused layout" },
    "branded" => { name: "Branded", description: "Logo header with accent color bar" },
    "editorial" => { name: "Editorial", description: "Magazine-style with large heading area" }
  }.freeze

  EMAIL_FONT_FAMILIES = {
    "system" => { name: "System Default", stack: "-apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif" },
    "georgia" => { name: "Georgia", stack: "Georgia, 'Times New Roman', Times, serif" },
    "helvetica" => { name: "Helvetica", stack: "Helvetica, Arial, sans-serif" },
    "verdana" => { name: "Verdana", stack: "Verdana, Geneva, sans-serif" }
  }.freeze

  HEX_COLOR_FORMAT = /\A#[0-9a-fA-F]{6}\z/

  included do
    has_one_attached :email_header_logo

    validates :email_default_template, inclusion: { in: EMAIL_TEMPLATES.keys }, allow_blank: true
    validates :email_font_family, inclusion: { in: EMAIL_FONT_FAMILIES.keys }, allow_blank: true
    validates :email_accent_color, format: { with: HEX_COLOR_FORMAT }, allow_blank: true
    validates :email_background_color, format: { with: HEX_COLOR_FORMAT }, allow_blank: true
    validates :email_body_text_color, format: { with: HEX_COLOR_FORMAT }, allow_blank: true
    validates :email_heading_color, format: { with: HEX_COLOR_FORMAT }, allow_blank: true
  end

  def email_font_stack
    EMAIL_FONT_FAMILIES.dig(email_font_family || "system", :stack) || EMAIL_FONT_FAMILIES["system"][:stack]
  end

  def email_header_logo_url
    return nil unless email_header_logo.attached?
    Rails.application.routes.url_helpers.rails_blob_url(email_header_logo, only_path: false, host: default_url_host)
  end

  private

  def default_url_host
    Rails.application.routes.default_url_options[:host] || "localhost:3000"
  end
end
