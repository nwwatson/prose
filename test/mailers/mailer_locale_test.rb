require "test_helper"

# Mail is built outside site requests (jobs, API calls), so every mailer has to
# pick up the site locale itself.
class MailerLocaleTest < ActionMailer::TestCase
  include LocaleHelper

  setup do
    spanish_site!
    @site_name = SiteSetting.current.site_name
    @subscriber = subscribers(:confirmed)
    @subscriber.generate_auth_token!
  end

  test "subscriber confirmation" do
    mail = SubscriberMailer.confirmation(@subscriber)

    assert_equal es("subscriber_mailer.confirmation.subject", site_name: @site_name), mail.subject
    assert_bodies mail, es("subscriber_mailer.confirmation.thanks")
  end

  test "subscriber magic link" do
    mail = SubscriberMailer.magic_link(@subscriber)

    assert_equal es("subscriber_mailer.magic_link.subject", site_name: @site_name), mail.subject
    assert_bodies mail, es("subscriber_mailer.magic_link.click_to_sign_in")
  end

  test "post notification" do
    post = posts(:published_post)
    mail = PostNotificationMailer.new_post(@subscriber, post)

    assert_equal es("post_notification_mailer.new_post.subject", title: post.title), mail.subject
    assert_bodies mail, es("post_notification_mailer.new_post.read_full_post")
    assert_bodies mail, es("mailer.footer.unsubscribe")
  end

  test "digest" do
    post = posts(:published_post)
    mail = DigestMailer.digest(@subscriber, [ post.id ])

    assert_equal es("digest_mailer.digest.subject", count: 1, site_name: @site_name), mail.subject
    assert_bodies mail, es("digest_mailer.digest.read_more")
    assert_bodies mail, I18n.l(post.published_at.to_date, format: :long, locale: :es)
  end

  test "comment reply notification" do
    reply = comments(:reply)
    reply.parent_comment.update!(notify_on_reply: true)
    mail = CommentMailer.reply_notification(reply)

    assert_equal es("comment_mailer.reply_notification.subject", site_name: @site_name), mail.subject
    assert_bodies mail, es("comment_mailer.reply_notification.view_comment")
  end

  test "newsletter footer" do
    mail = NewsletterMailer.campaign(@subscriber, newsletters(:sent_newsletter))

    assert_bodies mail, es("mailer.footer.unsubscribe")
    assert_not_includes mail.text_part.decoded, "Unsubscribe:"
  end

  test "rendering a mail leaves the caller's locale alone" do
    SubscriberMailer.magic_link(@subscriber).subject

    assert_equal :en, I18n.locale
  end

  private

  def es(key, **options)
    I18n.t(key, locale: :es, raise: true, **options)
  end

  def assert_bodies(mail, text)
    assert_includes mail.html_part.decoded, ERB::Util.html_escape(text)
    assert_includes mail.text_part.decoded, text
  end
end
