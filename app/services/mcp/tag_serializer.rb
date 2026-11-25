module Mcp
  # Tag JSON shared by MCP and the REST API. `detailed: false` is the summary
  # shape embedded in site info.
  class TagSerializer
    def self.all(detailed: true)
      post_counts = Tag.post_counts
      Tag.order(:name).map { |tag| call(tag, post_count: post_counts.fetch(tag.id, 0), detailed: detailed) }
    end

    def self.call(tag, post_count: nil, detailed: true)
      data = detailed ? { id: tag.id, name: tag.name, slug: tag.slug } : { name: tag.name, slug: tag.slug }
      post_count.nil? ? data : data.merge(post_count: post_count)
    end
  end
end
