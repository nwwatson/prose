module Imports
  module Ghost
    # Ghost-specific conversion on top of Imports::ContentConverter.
    #
    # Ghost exports write site-relative URLs as "__GHOST_URL__/…"; they are
    # rewritten to the site URL the admin supplied (or left relative, which
    # makes those images fail to download and be reported). Koenig cards
    # (class="kg-card kg-<type>-card") are mapped to plain HTML:
    #
    #   image / gallery      → images (attachments via the base class)
    #   bookmark / button    → link paragraph
    #   file                 → link paragraph to the file
    #   callout              → blockquote
    #   embed                → unwrapped (YouTube/Vimeo iframes already links)
    #   audio / video        → removed with a warning
    #   signup               → removed (member signup forms don't apply)
    #   other kg-* wrappers  → unwrapped, keeping their text
    class ContentConverter < Imports::ContentConverter
      PLACEHOLDER = "__GHOST_URL__".freeze
      RESIZED_IMAGE = %r{/content/images/size/w\d+(?:h\d+)?/}
      CARD_MARKER = /<!--\s*kg-card-(?:begin|end):[^>]*-->/

      private

      def preprocess(html)
        html.gsub(CARD_MARKER, "").gsub(PLACEHOLDER, @site_url.to_s.chomp("/"))
      end

      def transform(fragment)
        each_card(fragment, "bookmark") do |card|
          anchor = card.at_css("a")
          title = card.at_css(".kg-bookmark-title")&.text
          replace_with_link(card, anchor&.[]("href"), title)
        end
        each_card(fragment, "button") { |card| replace_with_link(card, card.at_css("a")&.[]("href"), card.at_css("a")&.text) }
        each_card(fragment, "file") do |card|
          replace_with_link(card, card.at_css("a")&.[]("href"), card.at_css(".kg-file-card-title")&.text)
        end
        each_card(fragment, "callout") do |card|
          emoji = card.at_css(".kg-callout-emoji")&.text.to_s.strip
          text = card.at_css(".kg-callout-text")&.inner_html.to_s
          card.replace("<blockquote><p>#{ERB::Util.html_escape(emoji)} #{text}</p></blockquote>")
        end
        %w[audio video].each do |type|
          each_card(fragment, type) do |card|
            warn("Removed unsupported #{type} card")
            card.remove
          end
        end
        each_card(fragment, "signup", &:remove)
        fragment.css("audio, video, source, track").each(&:remove)

        # Gallery/embed/header/toggle/product wrappers: keep the contents.
        fragment.css("[class*='kg-']").reverse_each do |node|
          next if node.name == "figure" && node.at_css("img")

          unwrap(node) if %w[div figure span].include?(node.name)
        end
      end

      # Ghost references responsive variants (/content/images/size/w600/…);
      # the original lives at the same path without the size segment.
      def image_candidates(img)
        src = absolute_url(img["src"].to_s)
        [ src.sub(RESIZED_IMAGE, "/content/images/"), src ].compact_blank
      end

      def each_card(fragment, type, &block)
        fragment.css(".kg-#{type}-card").each(&block)
      end

      def replace_with_link(card, url, text)
        if url.present?
          card.replace("<p>#{link(url, text.to_s.squish.presence || url)}</p>")
        else
          card.remove
        end
      end

      def unwrap(node)
        node.add_next_sibling(node.children)
        node.remove
      end
    end
  end
end
