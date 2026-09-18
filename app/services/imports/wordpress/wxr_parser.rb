module Imports
  module Wordpress
    # Parses a WordPress eXtended RSS (WXR) export into plain Item values.
    #
    # Namespace URIs are read from the document rather than hard-coded because
    # WordPress has shipped WXR 1.0, 1.1 and 1.2 (wordpress.org/export/1.x/).
    # remove_namespaces! can't be used: content:encoded and excerpt:encoded
    # would both collapse to <encoded>.
    class WxrParser
      class InvalidFile < StandardError; end

      Term = Data.define(:name, :slug)

      Item = Data.define(
        :wp_id, :post_type, :title, :slug, :status, :content, :excerpt,
        :published_at, :categories, :tags, :featured_image_url, :menu_order
      )

      IMPORTABLE_TYPES = %w[post page].freeze
      EMPTY_DATE = /\A0000-00-00/

      attr_reader :site_url

      def self.parse(io)
        new(io).items
      end

      def initialize(io)
        # NONET blocks external entity/DTD fetches (XXE); recover (the default)
        # tolerates the slightly malformed XML some WordPress plugins produce.
        @doc = Nokogiri::XML(io) { |config| config.nonet }
        root = @doc.root
        raise InvalidFile, "Not a WordPress export file" unless root&.name == "rss"

        @ns = {
          "wp" => namespace_uri(root, "wp"),
          "content" => namespace_uri(root, "content") || "http://purl.org/rss/1.0/modules/content/",
          "excerpt" => namespace_uri(root, "excerpt") || "http://wordpress.org/export/1.2/excerpt/"
        }
        raise InvalidFile, "Not a WordPress export file" if @ns["wp"].blank?

        @site_url = @doc.at_xpath("//channel/link")&.text.to_s.strip.presence
      end

      # Posts and pages only; attachments are used to resolve featured images.
      def items
        attachments = attachment_urls

        @doc.xpath("//channel/item").filter_map do |node|
          post_type = text(node, "wp:post_type")
          next unless IMPORTABLE_TYPES.include?(post_type)

          build_item(node, post_type, attachments)
        end
      end

      private

      def namespace_uri(root, prefix)
        root.namespaces["xmlns:#{prefix}"]
      end

      def build_item(node, post_type, attachments)
        Item.new(
          wp_id: text(node, "wp:post_id"),
          post_type: post_type,
          title: CGI.unescapeHTML(node.at_xpath("title")&.text.to_s.strip),
          slug: CGI.unescape(text(node, "wp:post_name")),
          status: text(node, "wp:status"),
          content: text(node, "content:encoded"),
          excerpt: text(node, "excerpt:encoded"),
          published_at: published_at(node),
          categories: terms(node, "category"),
          tags: terms(node, "post_tag"),
          featured_image_url: attachments[thumbnail_id(node)],
          menu_order: text(node, "wp:menu_order").to_i
        )
      end

      def attachment_urls
        @doc.xpath("//channel/item[wp:post_type='attachment']", @ns).each_with_object({}) do |node, urls|
          url = text(node, "wp:attachment_url")
          urls[text(node, "wp:post_id")] = url if url.present?
        end
      end

      def thumbnail_id(node)
        meta = node.xpath("wp:postmeta", @ns).find { |m| text(m, "wp:meta_key") == "_thumbnail_id" }
        meta && text(meta, "wp:meta_value")
      end

      def terms(node, domain)
        node.xpath("category[@domain='#{domain}']").map do |term|
          Term.new(name: CGI.unescapeHTML(term.text.strip), slug: term["nicename"].to_s)
        end
      end

      # post_date_gmt is "0000-00-00 00:00:00" for never-published drafts, so
      # fall back to the local post_date (interpreted as UTC).
      def published_at(node)
        [ "wp:post_date_gmt", "wp:post_date" ].each do |path|
          value = text(node, path)
          next if value.blank? || value.match?(EMPTY_DATE)

          return Time.find_zone("UTC").parse(value)
        rescue ArgumentError
          next
        end
        nil
      end

      def text(node, path)
        node.at_xpath(path, @ns)&.text.to_s.strip
      end
    end
  end
end
