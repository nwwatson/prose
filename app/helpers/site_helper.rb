module SiteHelper
  def site_name
    SiteSetting.current.site_name
  end

  def site_description
    SiteSetting.current.site_description
  end

  def default_og_image_url
    setting = SiteSetting.current
    if setting.default_og_image.attached?
      rails_storage_proxy_url(setting.default_og_image)
    end
  end

  def font_stylesheet_tags
    setting = SiteSetting.current
    url = setting.google_fonts_url
    return "".html_safe unless url

    safe_join([
      tag.link(rel: "preconnect", href: "https://fonts.googleapis.com"),
      tag.link(rel: "preconnect", href: "https://fonts.gstatic.com", crossorigin: "anonymous"),
      tag.link(href: url, rel: "stylesheet")
    ], "\n")
  end

  def typography_style_tag
    setting = SiteSetting.current

    css = <<~CSS
      :root {
        --font-display: #{setting.font_family_value(setting.heading_font)};
        --font-subtitle: #{setting.font_family_value(setting.subtitle_font)};
        --font-serif: #{setting.font_family_value(setting.body_font)};
        --heading-font-size: #{setting.heading_font_size}rem;
        --subtitle-font-size: #{setting.subtitle_font_size}rem;
        --body-font-size: #{setting.body_font_size}rem;
      }
      article h1 { font-size: var(--heading-font-size); }
      .font-subtitle { font-size: var(--subtitle-font-size); }
      .prose { font-size: var(--body-font-size); }
    CSS

    tag.style(css.html_safe)
  end
end
