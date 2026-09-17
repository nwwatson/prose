module Imports
  # Base class for converting another platform's post HTML into HTML that
  # ActionText/Lexxy can store. Subclasses add platform syntax through two
  # hooks and inherit the shared, security-relevant steps:
  #
  #   preprocess(html)     string-level rewrites (shortcodes, placeholders)
  #   transform(fragment)  DOM rewrites that need the source markup's classes
  #
  # Pipeline: preprocess → drop unsafe tags → video iframes become links →
  # transform → each <img> is downloaded into an ActionText attachment (a
  # failed download keeps the remote <img>) → strip presentational and event
  # attributes → drop empty paragraphs. Attributes are stripped late so
  # transform can still match on class names.
  class ContentConverter
    UNSAFE_TAGS = %w[script style noscript form input button select textarea object embed link meta].freeze
    STRIPPED_ATTRIBUTES = %w[class style id srcset sizes width height loading decoding].freeze
    VIDEO_IFRAME = %r{\A(?:https?:)?//(?:www\.)?(?:youtube(?:-nocookie)?\.com/embed/([\w-]+)|player\.vimeo\.com/video/(\d+))}i
    IMAGE_EXTENSION = /\.(?:jpe?g|png|gif|webp|avif)(?:\?.*)?\z/i

    def initialize(downloader:, site_url: nil, warn: ->(_message) { })
      @downloader = downloader
      @site_url = site_url.presence
      @warn = warn
    end

    def convert(html, title: nil)
      @title = title
      html = preprocess(html.to_s.gsub(/\r\n?/, "\n"))

      fragment = Nokogiri::HTML5.fragment(html)
      fragment.css(UNSAFE_TAGS.join(",")).each(&:remove)
      convert_iframes(fragment)
      transform(fragment)
      convert_images(fragment)
      strip_attributes(fragment)
      remove_empty_paragraphs(fragment)
      fragment.to_html.strip
    end

    private

    def preprocess(html)
      html
    end

    def transform(_fragment)
    end

    # Ordered URLs to try for an <img>; the first successful download wins.
    def image_candidates(img)
      [ img["src"] ].compact_blank.map { |url| absolute_url(url) }
    end

    def convert_iframes(fragment)
      fragment.css("iframe").each do |iframe|
        url = video_url(iframe["src"].to_s)
        if url
          # Inside a paragraph a nested <p> would be invalid.
          iframe.replace(iframe.parent&.name == "p" ? link(url) : "<p>#{link(url)}</p>")
        else
          warn("Removed embedded iframe (#{iframe["src"].to_s.truncate(80)})")
          iframe.remove
        end
      end
    end

    def video_url(src)
      match = src.match(VIDEO_IFRAME)
      return unless match

      match[1] ? "https://www.youtube.com/watch?v=#{match[1]}" : "https://vimeo.com/#{match[2]}"
    end

    # Containers are resolved for every image before any replacement: replacing
    # one gallery image would otherwise make its sibling look like the figure's
    # only image, and that sibling's replacement would delete the whole figure.
    def convert_images(fragment)
      fragment.css("img").map { |img| [ img, image_container(img) ] }.each do |img, container|
        blob = image_candidates(img).uniq.lazy.filter_map { |url| @downloader.download(url) }.first

        unless blob
          warn("Kept remote image #{img["src"].to_s.truncate(80)} (download failed)")
          next
        end

        caption = container.name == "figure" ? container.at_css("figcaption")&.text.to_s.strip : ""
        container.replace(ActionText::Attachment.from_attachable(blob, caption: caption.presence).to_html)
      end
    end

    # A linked image is replaced together with its link, and a figure together
    # with its caption — but only when the figure holds just this one image
    # (galleries keep one attachment per image).
    def image_container(img)
      container = img
      container = img.parent if img.parent&.name == "a" && img.parent.element_children.size == 1
      figure = container.parent
      container = figure if figure&.name == "figure" && figure.css("img").size == 1
      container
    end

    def strip_attributes(fragment)
      fragment.traverse do |node|
        next unless node.element? && node.name != ActionText::Attachment.tag_name

        node.attribute_nodes.each do |attr|
          attr.remove if STRIPPED_ATTRIBUTES.include?(attr.name) || attr.name.start_with?("data-", "on")
        end
      end
    end

    def remove_empty_paragraphs(fragment)
      fragment.css("p").each do |paragraph|
        paragraph.remove if paragraph.element_children.empty? && paragraph.text.strip.empty?
      end
    end

    def absolute_url(url)
      return url if @site_url.nil? || url.match?(%r{\Ahttps?://}i)

      URI.join(@site_url, url).to_s
    rescue URI::Error
      url
    end

    def link_paragraph(url, text = url)
      "\n\n<p>#{link(url, text)}</p>\n\n"
    end

    def link(url, text = url)
      "<a href=\"#{ERB::Util.html_escape(url.to_s.strip)}\">#{ERB::Util.html_escape(text.to_s.strip)}</a>"
    end

    def warn(message)
      @warn.call(@title.present? ? "#{@title}: #{message}" : message)
    end
  end
end
