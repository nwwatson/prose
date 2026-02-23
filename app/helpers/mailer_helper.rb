module MailerHelper
  def unsubscribe_url_for(subscriber)
    token = Rails.application.message_verifier("unsubscribe").generate(
      subscriber.id,
      expires_in: 30.days
    )
    unsubscribe_url(token: token)
  end
end
