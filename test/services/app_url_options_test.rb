require "test_helper"

class AppUrlOptionsTest < ActiveSupport::TestCase
  test "uses the action mailer default url options" do
    assert_equal({ host: "example.com" }, AppUrlOptions.call)
  end

  test "falls back to localhost when action mailer options are unset" do
    original = Rails.application.config.action_mailer.default_url_options
    Rails.application.config.action_mailer.default_url_options = nil

    assert_equal({ host: "localhost", port: 3000 }, AppUrlOptions.call)
  ensure
    Rails.application.config.action_mailer.default_url_options = original
  end
end
