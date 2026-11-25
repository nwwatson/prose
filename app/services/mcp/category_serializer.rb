module Mcp
  # Category JSON shared by MCP and the REST API. `detailed: false` is the
  # summary shape embedded in site info.
  class CategorySerializer
    def self.all(detailed: true)
      post_counts = Category.post_counts
      Category.ordered.map { |category| call(category, post_count: post_counts.fetch(category.id, 0), detailed: detailed) }
    end

    def self.call(category, post_count:, detailed: true)
      summary = { name: category.name, slug: category.slug, post_count: post_count }
      return summary unless detailed

      { id: category.id, name: category.name, slug: category.slug, description: category.description,
        position: category.position, post_count: post_count }
    end
  end
end
