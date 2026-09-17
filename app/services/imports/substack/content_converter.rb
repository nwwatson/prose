module Imports
  module Substack
    # Substack-specific conversion on top of Imports::ContentConverter.
    #
    # Substack post bodies are editor output with embeds serialized as JSON in
    # data-attrs (base strips data-* only after #transform, so it's readable):
    #
    #   subscribe widgets / paywall markers / subscribe & share buttons → removed
    #   other buttons                                     → link paragraph
    #   youtube-wrap / vimeo-wrap                          → video link
    #   tweet / embedded-post-wrap / spotify / soundcloud  → link paragraph
    #   pullquote                                          → blockquote
    #   captioned-image-container / picture / image insets → unwrapped
    #
    # Images are served through substackcdn.com/image/fetch/<transforms>/<url>;
    # the original upload is the URL-encoded last segment, so it is tried first.
    class ContentConverter < Imports::ContentConverter
      REMOVED = [
        ".subscription-widget-wrap", ".subscription-widget-wrap-editor", ".subscription-widget",
        "[data-component-name^='SubscribeWidget']", ".paywall-jump", "[data-component-name^='Paywall']",
        ".image-link-expand", "svg", "picture source"
      ].freeze
      LINK_EMBEDS = {
        ".tweet" => "url", ".embedded-post-wrap" => "url", ".spotify-wrap" => "url",
        ".soundcloud-wrap" => "url", ".apple-podcast-container" => "url"
      }.freeze
      SUBSCRIBE_OR_SHARE = %r{/subscribe\b|[?&]action=share|/share\b|substack\.com/refer}i
      CDN_FETCH = %r{\Ahttps?://substackcdn\.com/image/fetch/[^/]+/(.+)\z}i

      private

      def transform(fragment)
        fragment.css(REMOVED.join(",")).each(&:remove)
        convert_buttons(fragment)
        convert_videos(fragment)
        LINK_EMBEDS.each do |selector, key|
          fragment.css(selector).each do |node|
            attrs = data_attrs(node)
            replace_with_link(node, attrs[key], attrs["title"])
          end
        end
        fragment.css(".pullquote").each { |node| node.name = "blockquote" }
        fragment.css("picture, .image2-inset, .captioned-image-container").reverse_each { |node| unwrap(node) }
      end

      def convert_buttons(fragment)
        fragment.css(".button-wrapper, .captioned-button-wrap").each do |wrapper|
          anchor = wrapper.at_css("a")
          href = anchor&.[]("href").to_s
          if href.blank? || href.match?(SUBSCRIBE_OR_SHARE)
            wrapper.remove
          else
            replace_with_link(wrapper, href, anchor.text)
          end
        end
      end

      def convert_videos(fragment)
        fragment.css(".youtube-wrap").each do |node|
          video_id = data_attrs(node)["videoId"]
          replace_with_link(node, video_id.present? ? "https://www.youtube.com/watch?v=#{video_id}" : nil)
        end
        fragment.css(".vimeo-wrap").each do |node|
          video_id = data_attrs(node)["videoId"]
          replace_with_link(node, video_id.present? ? "https://vimeo.com/#{video_id}" : nil)
        end
      end

      def image_candidates(img)
        href = img.ancestors("a").first&.[]("href").to_s
        stored = data_attrs(img)["src"]
        [ original_url(href), stored, original_url(img["src"].to_s), img["src"] ]
          .compact_blank.select { |url| url.match?(%r{\Ahttps?://}i) }
      end

      def original_url(url)
        encoded = url[CDN_FETCH, 1]
        return (url.match?(IMAGE_EXTENSION) ? url : nil) unless encoded

        CGI.unescape(encoded)
      end

      def data_attrs(node)
        JSON.parse(node["data-attrs"].to_s)
      rescue JSON::ParserError
        {}
      end

      def replace_with_link(node, url, text = nil)
        if url.to_s.match?(%r{\Ahttps?://}i)
          node.replace("<p>#{link(url, text.to_s.squish.presence || url)}</p>")
        else
          node.remove
        end
      end

      def unwrap(node)
        node.add_next_sibling(node.children)
        node.remove
      end
    end
  end
end
