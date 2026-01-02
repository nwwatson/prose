require "test_helper"

class UserMailerTest < ActionMailer::TestCase
  test "confirmation_instructions" do
    mail = UserMailer.confirmation_instructions
    assert_equal "Confirmation instructions", mail.subject
    assert_equal [ "to@example.org" ], mail.to
    assert_equal [ "from@example.com" ], mail.from
    assert_match "Hi", mail.body.encoded
  end

  test "password_reset_instructions" do
    mail = UserMailer.password_reset_instructions
    assert_equal "Password reset instructions", mail.subject
    assert_equal [ "to@example.org" ], mail.to
    assert_equal [ "from@example.com" ], mail.from
    assert_match "Hi", mail.body.encoded
  end
end
