module Webhooks
  class PostSerializer
    def self.call(post)
      {
        id: post.id,
        title: post.title,
        slug: post.slug,
        status: post.status,
        url: post_url(post),
        author: post.user&.display_name,
        published_at: post.published_at&.iso8601,
        updated_at: post.updated_at.iso8601
      }
    end

    def self.post_url(post)
      Rails.application.routes.url_helpers.post_url(post, slug: post.slug, host: default_url_host)
    end

    def self.default_url_host
      Rails.application.routes.default_url_options[:host] || "localhost:3000"
    end
  end
end
