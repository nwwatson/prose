class UserMailer < ApplicationMailer
  default from: "noreply@prose-newsletter.com"

  def confirmation_instructions(user)
    @user = user
    @confirmation_url = confirmation_url(token: @user.confirmation_token)

    mail(
      to: @user.email,
      subject: "Confirm your Prose account"
    )
  end

  def password_reset_instructions(user)
    @user = user
    @reset_url = new_password_reset_url(token: @user.reset_password_token)

    mail(
      to: @user.email,
      subject: "Reset your Prose password"
    )
  end
end
