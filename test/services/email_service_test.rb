require "test_helper"

class EmailServiceTest < ActiveSupport::TestCase
  test "from_address defaults to noreply@example.com" do
    ENV.delete("SMTP_FROM")
    assert_equal "noreply@example.com", EmailService.from_address
  end

  test "from_address uses SMTP_FROM when set" do
    ENV["SMTP_FROM"] = "hello@example.com"
    assert_equal "hello@example.com", EmailService.from_address
  ensure
    ENV.delete("SMTP_FROM")
  end
end
