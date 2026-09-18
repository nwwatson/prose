module Imports
  module Wordpress
    # WordPress-specific conversion on top of Imports::ContentConverter:
    #
    # 1. Strip Gutenberg block delimiter comments (<!-- wp:paragraph -->).
    # 2. Rewrite shortcodes: [caption] → <figure>, [embed]/[youtube] → links,
    #    media shortcodes ([gallery], [audio], ...) are removed with a warning.
    #    Unrecognized shortcodes are left in place as text (so "[sic]" survives)
    #    and reported as warnings.
    # 3. Add paragraphs to classic-editor content, which WordPress stores with
    #    bare newlines and renders through wpautop(). Block content is skipped,
    #    matching WordPress, which never runs wpautop on block content.
    # 4. Gutenberg embed figures become links; linked full-size images are
    #    preferred over the resized <img src>.
    class ContentConverter < Imports::ContentConverter
      REMOVED_SHORTCODES = %w[gallery audio video playlist].freeze
      SHORTCODE = /\[\/?([a-z][a-z0-9_-]*)(?:[\s=][^\]]*)?\]/i
      BLOCK_TAG = /\A<(?:p|h[1-6]|ul|ol|li|blockquote|pre|figure|figcaption|div|table|thead|tbody|tr|td|th|hr|section|article|aside|iframe|dl|dt|dd|address)\b/i
      PRE_PLACEHOLDER_PATTERN = /PROSEPREBLOCK(\d+)END/

      private

      def preprocess(html)
        block_content = html.include?("<!-- wp:")
        html = html.gsub(/<!--\s*\/?wp:.*?-->/m, "")
        html = convert_shortcodes(html)
        block_content ? html : autop(html)
      end

      # Gutenberg embed blocks render as <figure><div>URL</div></figure>.
      def transform(fragment)
        fragment.css("figure").each do |figure|
          next if figure.at_css("img")

          url = figure.text.strip[%r{\Ahttps?://\S+\z}]
          figure.replace(link_paragraph(url).strip) if url
        end
      end

      # WordPress inserts resized variants (photo-300x200.jpg) and links them to
      # the full-size file, so prefer the link target when it is an image.
      def image_candidates(img)
        href = img.parent&.name == "a" ? img.parent["href"].to_s : ""
        [ href.match?(IMAGE_EXTENSION) ? href : nil, img["src"] ].compact_blank.map { |url| absolute_url(url) }
      end

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
    end
  end
end
