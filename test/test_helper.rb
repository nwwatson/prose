ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # Ensure RubyLLM model registry is populated and configured for tests
    parallelize_setup do
      if Model.none?
        RubyLLM.models.load_from_json!
        Model.save_to_database
      end
    end

    setup do
      RubyLLM.configure do |config|
        config.anthropic_api_key = "test-key"
        config.gemini_api_key = "test-key"
        config.openai_api_key = "test-key"
      end
    end

    # I18n.locale is a global set per-request by ApplicationController; reset it so a
    # test that renders in a non-default locale can't leak into unrelated tests sharing
    # the same parallel worker (e.g. mailer tests, which don't go through a controller).
    teardown do
      I18n.locale = I18n.default_locale
    end

    def with_fragment_caching
      original_cache_store = Rails.cache
      original_perform_caching = ActionController::Base.perform_caching
      Rails.cache = ActiveSupport::Cache::MemoryStore.new
      ActionController::Base.perform_caching = true
      yield
    ensure
      Rails.cache = original_cache_store
      ActionController::Base.perform_caching = original_perform_caching
    end

    def assert_query_count(expected, table:)
      count = 0
      counter = ->(*, payload) do
        count += 1 if payload[:sql].match?(/\bFROM\s+"?#{table}"?/i) && payload[:name] != "SCHEMA"
      end

      ActiveSupport::Notifications.subscribed(counter, "sql.active_record") { yield }

      assert_equal expected, count, "expected #{expected} queries against #{table}, got #{count}"
    end
  end
end

class ActionDispatch::IntegrationTest
  def sign_in(user)
    post admin_session_path, params: { email: user.email, password: "P@ssw0rd!Strong1" }
    follow_redirect! if response.redirect?
  end

  def sign_in_as(fixture_name)
    sign_in(users(fixture_name))
  end

  def sign_in_subscriber(subscriber)
    subscriber.generate_auth_token!
    get subscriber_session_path(token: subscriber.auth_token)
  end
end

module ActivityPubTestHelper
  include ActiveJob::TestHelper

  REMOTE_KEY = OpenSSL::PKey::RSA.new(2048)
  REMOTE_ACTOR_URI = "https://remote.example/users/alice".freeze
  REMOTE_KEY_ID = "#{REMOTE_ACTOR_URI}#main-key".freeze

  def enable_federation!(**attrs)
    SiteSetting.current.update!(activitypub_enabled: true, **attrs)
  end

  def remote_actor(**attrs)
    FediverseActor.create!({
      uri: REMOTE_ACTOR_URI,
      inbox_url: "#{REMOTE_ACTOR_URI}/inbox",
      shared_inbox_url: "https://remote.example/inbox",
      key_id: REMOTE_KEY_ID,
      public_key_pem: REMOTE_KEY.public_to_pem,
      username: "alice",
      name: "Alice",
      profile_url: "https://remote.example/@alice",
      fetched_at: Time.current
    }.merge(attrs))
  end

  # Headers for a request signed by the remote test actor, as Mastodon sends them.
  def signed_inbox_headers(body, key: REMOTE_KEY, key_id: REMOTE_KEY_ID, path: "/activitypub/inbox")
    ActivityPub::Signature.sign(method: :post, url: "http://www.example.com#{path}", key: key, key_id: key_id, body: body)
      .merge("Content-Type" => "application/activity+json")
  end

  # Temporarily replaces a singleton method (Minitest 6 no longer ships #stub).
  def with_singleton_stub(object, method_name, implementation)
    original = object.method(method_name)
    object.define_singleton_method(method_name, &implementation)
    yield
  ensure
    object.define_singleton_method(method_name, original)
  end
end
