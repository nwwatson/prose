module Mcp
  # Creates and updates posts for the MCP tools and the REST API with one save,
  # so each callback, webhook and federation job fires once.
  #
  # Only keys present in `attrs` are written. `content` is markdown; passing it
  # blank clears the body. `category` is a name or slug; blank clears it and an
  # unknown one raises UnknownCategory. `tags` replaces the post's tags.
  class PostWriter
    include Mcp::ContentLookup

    class UnknownCategory < StandardError; end

    ATTRIBUTES = %i[title subtitle slug meta_description featured].freeze

    def self.create(user:, attrs:)
      new(Post.new(user: user, status: :draft), attrs).write
    end

    def self.update(post:, attrs:)
      new(post, attrs).write
    end

    def initialize(post, attrs)
      @post = post
      @attrs = attrs.to_h.symbolize_keys
    end

    def write
      post.assign_attributes(attrs.slice(*ATTRIBUTES))
      post.category = resolve_category(attrs[:category]) if attrs.key?(:category)
      post.content = Mcp::MarkdownConverter.to_html(attrs[:content].to_s) if attrs.key?(:content)

      Post.transaction do
        # Always save: a content-only change lives on the ActionText record, so
        # `post.changed?` stays false and a guarded save would silently drop it.
        post.save!
        post.tags = find_or_create_tags(attrs[:tags]) if attrs.key?(:tags)
      end

      post.reload
    end

    private

    attr_reader :post, :attrs

    def resolve_category(name_or_slug)
      return nil if name_or_slug.blank?

      find_category(name_or_slug) || raise(UnknownCategory, "Category not found: #{name_or_slug}")
    end
  end
end
