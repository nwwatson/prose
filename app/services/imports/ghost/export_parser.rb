module Imports
  module Ghost
    # Parses a Ghost JSON export (Settings → Advanced → Export content) into
    # plain Item values.
    #
    # Ghost 1.x+ wraps the payload as {"db": [{"meta": ..., "data": ...}]};
    # some tools and older versions emit {"meta": ..., "data": ...} directly,
    # so both are accepted. Post content prefers the pre-rendered `html`, then
    # renders `mobiledoc`, and finally falls back to `plaintext` (Lexical-only
    # posts without html) — content_source records which one was used.
    class ExportParser
      class InvalidFile < StandardError; end

      Tag = Data.define(:name, :slug)

      Item = Data.define(
        :ghost_id, :post_type, :title, :slug, :status, :visibility, :featured,
        :content, :content_source, :unsupported_cards, :custom_excerpt,
        :meta_description, :published_at, :tags, :feature_image
      )

      def self.parse(io)
        new(io).items
      end

      def initialize(io)
        # ImportJob opens stored files in binary mode; Ghost exports are UTF-8.
        json = io.read.to_s.dup.force_encoding(Encoding::UTF_8).scrub
        @data = extract_data(JSON.parse(json))
      rescue JSON::ParserError
        raise InvalidFile, "Not a valid Ghost export file"
      end

      def items
        tags = Array(@data["tags"]).index_by { |tag| tag["id"] }
        post_tags = Array(@data["posts_tags"]).group_by { |row| row["post_id"] }
        meta = Array(@data["posts_meta"]).index_by { |row| row["post_id"] }

        Array(@data["posts"]).filter_map do |post|
          next unless %w[post page].include?(post["type"].presence || "post")

          build_item(post, tags_for(post, post_tags, tags), meta[post["id"]] || {})
        end
      end

      private

      def extract_data(json)
        payload = json.is_a?(Hash) && json["db"].is_a?(Array) ? json["db"].first : json
        data = payload.is_a?(Hash) ? payload["data"] : nil
        raise InvalidFile, "Not a Ghost export file" unless data.is_a?(Hash) && data["posts"].is_a?(Array)

        data
      end

      def build_item(post, tags, meta)
        content, source, unsupported = content_for(post)

        Item.new(
          ghost_id: post["id"].to_s,
          post_type: post["type"].presence || "post",
          title: post["title"].to_s.strip,
          slug: post["slug"].to_s,
          status: post["status"].to_s,
          visibility: post["visibility"].presence || "public",
          featured: post["featured"] == true || post["featured"].to_s == "1",
          content: content,
          content_source: source,
          unsupported_cards: unsupported,
          custom_excerpt: post["custom_excerpt"],
          meta_description: post["meta_description"].presence || meta["meta_description"],
          published_at: parse_time(post["published_at"]),
          tags: tags,
          feature_image: post["feature_image"].presence
        )
      end

      # Posts are tagged in sort_order; internal tags (#hashtags) are Ghost's
      # private organisational labels and are never public.
      def tags_for(post, post_tags, tags)
        Array(post_tags[post["id"]]).sort_by { |row| row["sort_order"].to_i }.filter_map do |row|
          tag = tags[row["tag_id"]]
          next if tag.nil? || tag["visibility"] == "internal" || tag["name"].to_s.start_with?("#")

          Tag.new(name: tag["name"].to_s.strip, slug: tag["slug"].to_s)
        end
      end

      def content_for(post)
        if post["html"].present?
          [ post["html"], :html, [] ]
        elsif post["mobiledoc"].present?
          renderer = MobiledocRenderer.new(post["mobiledoc"])
          [ renderer.render, :mobiledoc, renderer.unsupported_cards.uniq ]
        else
          [ plaintext_html(post["plaintext"]), :plaintext, [] ]
        end
      rescue JSON::ParserError
        [ plaintext_html(post["plaintext"]), :plaintext, [] ]
      end

      def plaintext_html(text)
        text.to_s.split(/\n\s*\n/).map(&:strip).compact_blank.map { |paragraph| "<p>#{ERB::Util.html_escape(paragraph)}</p>" }.join("\n")
      end

      def parse_time(value)
        return if value.blank?

        value.is_a?(Numeric) ? Time.zone.at(value / 1000.0) : Time.zone.parse(value.to_s)
      rescue ArgumentError
        nil
      end
    end
  end
end
