module ActivityPub
  # Every ActivityPub id must be an absolute, stable URL, and they have to match
  # between the web request that serves an object and the background job that
  # delivers it. Both build them here from the mailer's default_url_options
  # (APP_HOST in production) rather than from the incoming request's host.
  module Urls
    PUBLIC_COLLECTION = "https://www.w3.org/ns/activitystreams#Public".freeze
    POST_PATH = %r{\A/posts/(?<slug>[a-z0-9]+(?:-[a-z0-9]+)*)/?\z}

    module_function

    def url_options
      options = (Rails.application.config.action_mailer.default_url_options || {}).slice(:host, :port, :protocol)
      options[:host] ||= "localhost"
      options[:protocol] ||= Rails.application.config.force_ssl ? "https" : "http"
      options
    end

    # The authority used in the acct: handle, e.g. "example.com".
    def host
      url_options.values_at(:host, :port).compact.join(":")
    end

    def base_url
      helpers.root_url(**url_options).chomp("/")
    end

    def actor_url
      helpers.activity_pub_actor_url(**url_options)
    end

    def key_id
      "#{actor_url}#main-key"
    end

    def inbox_url
      helpers.activity_pub_inbox_url(**url_options)
    end

    def outbox_url
      helpers.activity_pub_outbox_url(**url_options)
    end

    def followers_url
      helpers.activity_pub_followers_url(**url_options)
    end

    def following_url
      helpers.activity_pub_following_url(**url_options)
    end

    def post_url(post)
      helpers.post_url(slug: post.slug, **url_options)
    end

    def tag_url(tag)
      helpers.tag_url(slug: tag.slug, **url_options)
    end

    def blob_url(blob)
      helpers.rails_blob_url(blob, **url_options)
    end

    def absolute(path)
      path.to_s.start_with?("/") && !path.to_s.start_with?("//") ? "#{base_url}#{path}" : path.to_s
    end

    # Returns the live Post an ActivityPub object id points at, or nil if the id
    # isn't one of this site's post URLs.
    def post_for(uri)
      parsed = URI.parse(uri.to_s)
      return unless parsed.host == url_options[:host]

      match = POST_PATH.match(parsed.path)
      Post.live.find_by(slug: match[:slug]) if match
    rescue URI::InvalidURIError
      nil
    end

    def helpers
      Rails.application.routes.url_helpers
    end
  end
end
