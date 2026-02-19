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
