class AddEmailBrandingToSiteSettings < ActiveRecord::Migration[8.1]
  def change
    change_table :site_settings do |t|
      t.string :email_accent_color, default: "#18181b"
      t.string :email_background_color, default: "#f4f4f5"
      t.string :email_body_text_color, default: "#3f3f46"
      t.string :email_heading_color, default: "#18181b"
      t.string :email_font_family, default: "system"
      t.text :email_footer_text, default: ""
      t.string :email_preheader_text, default: ""
      t.string :email_social_twitter
      t.string :email_social_github
      t.string :email_social_linkedin
      t.string :email_social_website
      t.string :email_default_template, default: "minimal"
    end
  end
end
