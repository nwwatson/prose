require "test_helper"

class NewsletterMailerTest < ActionMailer::TestCase
  test "campaign email has correct subject" do
    subscriber = subscribers(:confirmed)
    newsletter = newsletters(:sent_newsletter)
    email = NewsletterMailer.campaign(subscriber, newsletter)

    assert_equal newsletter.title, email.subject
    assert_equal [ subscriber.email ], email.to
  end

  test "campaign email includes List-Unsubscribe header" do
    subscriber = subscribers(:confirmed)
    newsletter = newsletters(:sent_newsletter)
    email = NewsletterMailer.campaign(subscriber, newsletter)

    assert email.header["List-Unsubscribe"].present?
    assert_match %r{/unsubscribe\?token=}, email.header["List-Unsubscribe"].value
  end

  test "campaign email includes List-Unsubscribe-Post header" do
    subscriber = subscribers(:confirmed)
    newsletter = newsletters(:sent_newsletter)
    email = NewsletterMailer.campaign(subscriber, newsletter)

    assert_equal "List-Unsubscribe=One-Click", email.header["List-Unsubscribe-Post"].value
  end

  test "campaign email text part includes unsubscribe URL" do
    subscriber = subscribers(:confirmed)
    newsletter = newsletters(:sent_newsletter)
    email = NewsletterMailer.campaign(subscriber, newsletter)

    assert_match %r{/unsubscribe\?token=}, email.text_part.body.to_s
  end

  test "campaign email html part includes unsubscribe link" do
    subscriber = subscribers(:confirmed)
    newsletter = newsletters(:sent_newsletter)
    email = NewsletterMailer.campaign(subscriber, newsletter)

    assert_match "Unsubscribe", email.html_part.body.to_s
  end

  test "campaign email renders minimal template by default" do
    subscriber = subscribers(:confirmed)
    newsletter = newsletters(:sent_newsletter)
    email = NewsletterMailer.campaign(subscriber, newsletter)

    assert_match newsletter.title, email.html_part.body.to_s
    assert_match SiteSetting.current.site_name, email.html_part.body.to_s
  end

  test "campaign email renders branded template" do
    subscriber = subscribers(:confirmed)
    newsletter = newsletters(:sent_newsletter)
    newsletter.update_columns(template: "branded")
    email = NewsletterMailer.campaign(subscriber, newsletter)

    html = email.html_part.body.to_s
    assert_match newsletter.title, html
    assert_match "height: 8px", html
  end

  test "campaign email renders editorial template" do
    subscriber = subscribers(:confirmed)
    newsletter = newsletters(:sent_newsletter)
    newsletter.update_columns(template: "editorial")
    email = NewsletterMailer.campaign(subscriber, newsletter)

    html = email.html_part.body.to_s
    assert_match newsletter.title, html
  end

  test "campaign email uses newsletter accent color override" do
    subscriber = subscribers(:confirmed)
    newsletter = newsletters(:sent_newsletter)
    newsletter.update_columns(accent_color: "#ff5500", template: "branded")
    email = NewsletterMailer.campaign(subscriber, newsletter)

    assert_match "#ff5500", email.html_part.body.to_s
  end

  test "campaign email includes preheader text when set" do
    subscriber = subscribers(:confirmed)
    newsletter = newsletters(:sent_newsletter)
    newsletter.update_columns(preheader_text: "Check out our latest update")
    email = NewsletterMailer.campaign(subscriber, newsletter)

    assert_match "Check out our latest update", email.html_part.body.to_s
  end
end
