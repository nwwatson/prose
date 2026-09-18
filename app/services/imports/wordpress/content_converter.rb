module Imports
  module Wordpress
    # Converts WordPress post HTML (Gutenberg or classic editor) into HTML that
    # ActionText/Lexxy can store:
    #
    # 1. Strip Gutenberg block delimiter comments (<!-- wp:paragraph -->).
    # 2. Rewrite shortcodes: [caption] → <figure>, [embed]/[youtube] → links,
    #    media shortcodes ([gallery], [audio], ...) are removed with a warning.
    #    Unrecognized shortcodes are left in place as text (so "[sic]" survives)
    #    and reported as warnings.
    # 3. Add paragraphs to classic-editor content, which WordPress stores with
    #    bare newlines and renders through wpautop(). Block content is skipped,
    #    matching WordPress, which never runs wpautop on block content.
    # 4. Drop scripts/styles/forms, turn YouTube/Vimeo iframes into links, and
    #    download each <img> into an ActionText attachment.
    class ContentConverter
      REMOVED_SHORTCODES = %w[gallery audio video playlist].freeze
      SHORTCODE = /\[\/?([a-z][a-z0-9_-]*)(?:[\s=][^\]]*)?\]/i
      BLOCK_TAG = /\A<(?:p|h[1-6]|ul|ol|li|blockquote|pre|figure|figcaption|div|table|thead|tbody|tr|td|th|hr|section|article|aside|iframe|dl|dt|dd|address)\b/i
      UNSAFE_TAGS = %w[script style noscript form input button select textarea object embed link meta].freeze
      STRIPPED_ATTRIBUTES = %w[class style id srcset sizes width height loading decoding].freeze
      VIDEO_IFRAME = %r{\A(?:https?:)?//(?:www\.)?(?:youtube(?:-nocookie)?\.com/embed/([\w-]+)|player\.vimeo\.com/video/(\d+))}i
      IMAGE_EXTENSION = /\.(?:jpe?g|png|gif|webp|avif)(?:\?.*)?\z/i
      PRE_PLACEHOLDER_PATTERN = /PROSEPREBLOCK(\d+)END/

      def initialize(downloader:, site_url: nil, warn: ->(_message) { })
        @downloader = downloader
        @site_url = site_url.presence
        @warn = warn
      end

      def convert(html, title: nil)
        @title = title
        html = html.to_s.gsub(/\r\n?/, "\n")
        block_content = html.include?("<!-- wp:")

        html = html.gsub(/<!--\s*\/?wp:.*?-->/m, "")
        html = convert_shortcodes(html)
        html = autop(html) unless block_content

        fragment = Nokogiri::HTML5.fragment(html)
        clean(fragment)
        convert_iframes(fragment)
        convert_embed_figures(fragment)
        convert_images(fragment)
        remove_empty_paragraphs(fragment)
        fragment.to_html.strip
      end

      private

      def convert_shortcodes(html)
        html = html.gsub(/\[caption[^\]]*\](.*?)\[\/caption\]/m) { caption_figure(Regexp.last_match(1)) }
        html = html.gsub(/\[embed[^\]]*\](.*?)\[\/embed\]/m) { link_paragraph(Regexp.last_match(1)) }
        html = html.gsub(/\[youtube[=\s]+([^\]\s]+)[^\]]*\]/i) { link_paragraph(Regexp.last_match(1).split("&w=").first) }

        REMOVED_SHORTCODES.each do |name|
          single = /\[#{name}\b[^\]]*\]/
          next unless html.match?(single)

          warn("Removed unsupported [#{name}] shortcode")
          html = html.gsub(/\[#{name}\b[^\]]*\].*?\[\/#{name}\]/m, "").gsub(single, "")
        end

        html.scan(SHORTCODE).flatten.map(&:downcase).uniq.each do |name|
          warn("Left unrecognized shortcode [#{name}] as text")
        end
        html
      end

      def caption_figure(inner)
        image = inner[/<a\b[^>]*>\s*<img\b[^>]*>\s*<\/a>|<img\b[^>]*>/m].to_s
        caption = inner.sub(image, "").strip
        "\n\n<figure>#{image}<figcaption>#{caption}</figcaption></figure>\n\n"
      end

      def link_paragraph(url)
        "\n\n<p>#{link(url)}</p>\n\n"
      end

      def link(url)
        escaped = ERB::Util.html_escape(url.to_s.strip)
        "<a href=\"#{escaped}\">#{escaped}</a>"
      end

      # A pragmatic port of WordPress's wpautop(): blank lines separate
      # paragraphs, single newlines become <br>. <pre> blocks are swapped for
      # placeholders first so their blank lines don't split them.
      def autop(html)
        preserved = []
        html = html.gsub(/<pre\b.*?<\/pre>/mi) do |match|
          preserved << match
          "PROSEPREBLOCK#{preserved.size - 1}END"
        end

        paragraphs = html.split(/\n\s*\n/).map(&:strip).reject(&:empty?).map do |chunk|
          if chunk.match?(BLOCK_TAG) || chunk.match?(/\A#{PRE_PLACEHOLDER_PATTERN}\z/)
            chunk
          else
            "<p>#{chunk.gsub(/\s*\n\s*/, "<br>\n")}</p>"
          end
        end

        paragraphs.join("\n").gsub(PRE_PLACEHOLDER_PATTERN) { preserved[Regexp.last_match(1).to_i] }
      end

      def clean(fragment)
        fragment.css(UNSAFE_TAGS.join(",")).each(&:remove)
        fragment.traverse do |node|
          next unless node.element?

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

      def convert_iframes(fragment)
        fragment.css("iframe").each do |iframe|
          url = video_url(iframe["src"].to_s)
          if url
            # Inside a paragraph (classic content) a nested <p> would be invalid.
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

      # Gutenberg embed blocks render as <figure><div>URL</div></figure>.
      def convert_embed_figures(fragment)
        fragment.css("figure").each do |figure|
          next if figure.at_css("img")

          url = figure.text.strip[%r{\Ahttps?://\S+\z}]
          figure.replace(link_paragraph(url).strip) if url
        end
      end

      # Containers are resolved for every image before any replacement: replacing
      # one image of a multi-image figure would otherwise detach its siblings
      # (or make one look like the figure's only image and delete the rest).
      def convert_images(fragment)
        fragment.css("img").map { |img| [ img, image_container(img) ] }.each do |img, container|
          blob = image_candidates(img).lazy.filter_map { |url| @downloader.download(url) }.first

          unless blob
            warn("Kept remote image #{img["src"].to_s.truncate(80)} (download failed)")
            next
          end

          caption = container.name == "figure" ? container.at_css("figcaption")&.text.to_s.strip : ""
          container.replace(ActionText::Attachment.from_attachable(blob, caption: caption.presence).to_html)
        end
      end

      # A linked image is replaced together with its link, and a figure together
      # with its caption — but only when the figure holds just this one image.
      def image_container(img)
        container = img
        container = img.parent if img.parent&.name == "a" && img.parent.element_children.size == 1
        figure = container.parent
        container = figure if figure&.name == "figure" && figure.css("img").size == 1
        container
      end

      # WordPress inserts resized variants (photo-300x200.jpg) and links them to
      # the full-size file, so prefer the link target when it is an image.
      def image_candidates(img)
        href = img.parent&.name == "a" ? img.parent["href"].to_s : ""
        [ href.match?(IMAGE_EXTENSION) ? href : nil, img["src"] ].compact_blank.map { |url| absolute_url(url) }.uniq
      end

      def absolute_url(url)
        return url if @site_url.nil? || url.match?(%r{\Ahttps?://}i)

        URI.join(@site_url, url).to_s
      rescue URI::Error
        url
      end

      def warn(message)
        @warn.call(@title.present? ? "#{@title}: #{message}" : message)
      end
    end
  end
end
