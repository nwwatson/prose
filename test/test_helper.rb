ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

Dir[File.expand_path("support/**/*.rb", __dir__)].sort.each { |file| require file }

module ActiveSupport
  class TestCase
    include StubbingHelper
    include HttpHelper
    include StripeHelper

    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

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

    def with_reading_list_limit(limit, &block)
      with_const(ReadingListItem, :MAX_ITEMS, limit, &block)
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
  include ApiHelper

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
