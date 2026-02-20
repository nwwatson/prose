module Mcp
  class PostSerializer
    def self.call(post, include_content: false)
      data = {
        id: post.id,
        title: post.title,
        subtitle: post.subtitle,
        slug: post.slug,
        status: post.status,
        featured: post.featured,
        reading_time_minutes: post.reading_time_minutes,
        meta_description: post.meta_description,
        published_at: post.published_at&.iso8601,
        scheduled_at: post.scheduled_at&.iso8601,
        created_at: post.created_at.iso8601,
        updated_at: post.updated_at.iso8601,
        author: post.user&.display_name,
        category: post.category&.name,
        tags: post.tags.pluck(:name)
      }

      if include_content
        data[:content_html] = post.content&.to_s
        data[:content_plain] = post.content&.to_plain_text
      end

      data
    end
  end
end
