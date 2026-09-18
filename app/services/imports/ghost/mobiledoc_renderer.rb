module Imports
  module Ghost
    # Renders a Ghost Mobiledoc document (format 0.3.x) to HTML. Only used when
    # an export has no pre-rendered `html` for a post (older Ghost versions).
    #
    # Sections: 1 = markup section [1, tag, markers], 2 = image [2, src],
    # 3 = list [3, tag, [markers, ...]], 10 = card [10, card_index].
    # Markers: [type (0 text / 1 atom), opened markup indexes, closed count, value].
    #
    # Output is unsanitized by design; Imports::Ghost::ContentConverter cleans
    # it like any other imported HTML.
    class MobiledocRenderer
      SECTION_TAGS = %w[p h1 h2 h3 h4 h5 h6 blockquote].freeze
      MARKUP_TAGS = %w[a b strong i em u s sub sup code].freeze
      IGNORED_CARDS = %w[paywall email email-cta].freeze

      attr_reader :unsupported_cards

      def self.render(json)
        new(json).render
      end

      def initialize(json)
        @doc = json.is_a?(String) ? JSON.parse(json) : json
        @unsupported_cards = []
      end

      def render
        Array(@doc["sections"]).map { |section| render_section(section) }.join("\n")
      end

      private

      def render_section(section)
        case section[0]
        when 1
          tag = SECTION_TAGS.include?(section[1].to_s.downcase) ? section[1].downcase : "p"
          "<#{tag}>#{render_markers(section[2])}</#{tag}>"
        when 2
          %(<figure><img src="#{h(section[1])}"></figure>)
        when 3
          tag = section[1] == "ol" ? "ol" : "ul"
          items = Array(section[2]).map { |markers| "<li>#{render_markers(markers)}</li>" }
          "<#{tag}>#{items.join}</#{tag}>"
        when 10
          render_card(*Array(@doc["cards"])[section[1]])
        else
          ""
        end
      end

      def render_markers(markers)
        open = []
        Array(markers).map do |type, opened, closed_count, value|
          html = +""
          Array(opened).each do |index|
            tag, attributes = markup(index)
            open << tag
            html << "<#{tag}#{attributes}>"
          end
          html << (type == 1 ? h(atom_text(value)) : h(value))
          closed_count.to_i.times { html << "</#{open.pop}>" if open.any? }
          html
        end.join + open.reverse.map { |tag| "</#{tag}>" }.join
      end

      def markup(index)
        tag, attributes = Array(@doc["markups"])[index]
        tag = tag.to_s.downcase
        return [ "span", "" ] unless MARKUP_TAGS.include?(tag)

        href = Array(attributes).each_slice(2).to_h["href"]
        [ tag, tag == "a" && href ? %( href="#{h(href)}") : "" ]
      end

      def atom_text(index)
        _name, text, _payload = Array(@doc["atoms"])[index]
        text.to_s
      end

      def render_card(name = nil, payload = {})
        payload ||= {}

        case name
        when "image"
          figure([ payload["src"] ], payload["caption"])
        when "gallery"
          figure(Array(payload["images"]).map { |image| image["src"] }, payload["caption"])
        when "markdown", "card-markdown"
          MarkdownRenderer.to_html(payload["markdown"].to_s, trusted: true)
        when "html"
          payload["html"].to_s
        when "hr"
          "<hr>"
        when "code"
          "<pre><code>#{h(payload["code"])}</code></pre>"
        when "embed"
          link_paragraph(payload["url"])
        when "bookmark"
          link_paragraph(payload["url"], payload.dig("metadata", "title"))
        when "button"
          link_paragraph(payload["buttonUrl"], payload["buttonText"])
        when "callout"
          "<blockquote><p>#{h([ payload["calloutEmoji"], payload["calloutText"] ].compact.join(" "))}</p></blockquote>"
        when *IGNORED_CARDS
          ""
        else
          @unsupported_cards << name.to_s
          ""
        end
      end

      # Captions in Mobiledoc may contain markup, so they are passed through.
      def figure(sources, caption)
        images = sources.compact_blank.map { |src| %(<img src="#{h(src)}">) }.join
        return "" if images.empty?

        caption_html = caption.present? ? "<figcaption>#{caption}</figcaption>" : ""
        "<figure>#{images}#{caption_html}</figure>"
      end

      def link_paragraph(url, text = nil)
        return "" if url.blank?

        %(<p><a href="#{h(url)}">#{h(text.presence || url)}</a></p>)
      end

      def h(value)
        ERB::Util.html_escape(value.to_s)
      end
    end
  end
end
