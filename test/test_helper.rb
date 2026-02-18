ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # Add more helper methods to be used by all tests here...
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
