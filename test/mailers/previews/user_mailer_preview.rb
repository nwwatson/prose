# Preview all emails at http://localhost:3000/rails/mailers/user_mailer
class UserMailerPreview < ActionMailer::Preview
  # Preview this email at http://localhost:3000/rails/mailers/user_mailer/confirmation_instructions
  def confirmation_instructions
    user = User.new(
      name: "John Doe",
      email: "john@example.com",
      confirmation_token: "abc123sample"
    )
    UserMailer.confirmation_instructions(user)
  end

  # Preview this email at http://localhost:3000/rails/mailers/user_mailer/password_reset_instructions
  def password_reset_instructions
    user = User.new(
      name: "John Doe",
      email: "john@example.com",
      reset_password_token: "xyz789sample"
    )
    UserMailer.password_reset_instructions(user)
  end
end
