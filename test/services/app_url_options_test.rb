require "test_helper"

class AppUrlOptionsTest < ActiveSupport::TestCase
  test "uses the action mailer host with http when SSL is not forced" do
    assert_equal({ host: "example.com", protocol: "http" }, AppUrlOptions.call)
  end

  test "uses https when SSL is forced" do
    with_url_config(force_ssl: true) do
      assert_equal({ host: "example.com", protocol: "https" }, AppUrlOptions.call)
    end
  end

  test "a configured protocol and port win" do
    with_url_config(options: { host: "blog.test", port: 8443, protocol: "https" }) do
      assert_equal({ host: "blog.test", port: 8443, protocol: "https" }, AppUrlOptions.call)
    end
  end

  test "falls back to localhost when action mailer options are unset" do
    with_url_config(options: nil) do
      assert_equal({ host: "localhost", port: 3000, protocol: "http" }, AppUrlOptions.call)
    end
  end

  test "webhook, email logo and ActivityPub URLs all use https when SSL is forced" do
    site = SiteSetting.current
    site.email_header_logo.attach(io: StringIO.new("logo"), filename: "logo.png", content_type: "image/png")
    post = posts(:published_post)

    with_url_config(force_ssl: true, options: { host: "blog.test" }) do
      post_url = "https://blog.test/posts/published-post"

      assert_equal post_url, Webhooks::PostSerializer.call(post)[:url]
      assert_equal post_url, ActivityPub::Urls.post_url(post)
      assert_equal "https://blog.test/activitypub/actor", ActivityPub::Urls.actor_url
      assert site.email_header_logo_url.start_with?("https://blog.test/rails/active_storage/")
    end
  end

  private

  def with_url_config(force_ssl: false, options: Rails.application.config.action_mailer.default_url_options)
    config = Rails.application.config
    original_options = config.action_mailer.default_url_options
    original_force_ssl = config.force_ssl
    config.action_mailer.default_url_options = options
    config.force_ssl = force_ssl
    yield
  ensure
    config.action_mailer.default_url_options = original_options
    config.force_ssl = original_force_ssl
  end
end
