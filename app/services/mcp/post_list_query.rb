module Mcp
  # Filtered, paginated post listing shared by the `list_posts` MCP tool and
  # `GET /api/v1/posts`. An unknown category or tag filter matches no posts
  # rather than being ignored.
  class PostListQuery
    include Mcp::ContentLookup

    DEFAULT_PER_PAGE = 20
    MAX_PER_PAGE = 50

    Result = Data.define(:posts, :total, :page, :per_page)

    def self.call(filters = {})
      new(filters).call
    end

    def initialize(filters = {})
      @filters = filters.to_h.symbolize_keys
    end

    def call
      scope = filtered_scope
      total = scope.count
      posts = scope.limit(per_page).offset((page - 1) * per_page).to_a

      Result.new(posts: posts, total: total, page: page, per_page: per_page)
    end

    private

    attr_reader :filters

    def filtered_scope
      posts = Post.for_listing.includes(:tags)
      posts = posts.where(status: filters[:status]) if filters[:status].present?

      if filters[:category].present?
        category = find_category(filters[:category])
        posts = category ? posts.where(category: category) : posts.none
      end

      if filters[:tag].present?
        tag = find_tag(filters[:tag])
        posts = tag ? posts.where(id: tag.posts.select(:id)) : posts.none
      end

      posts = posts.search(filters[:search]) if filters[:search].present?
      posts.order(created_at: :desc)
    end

    def page
      @page ||= [ filters[:page].to_i, 1 ].max
    end

    def per_page
      @per_page ||= begin
        value = (filters[:per_page] || DEFAULT_PER_PAGE).to_i
        value < 1 ? DEFAULT_PER_PAGE : [ value, MAX_PER_PAGE ].min
      end
    end
  end
end
