require "test_helper"

class DigestMailerTest < ActionMailer::TestCase
  setup do
    @subscriber = subscribers(:confirmed)
    @posts = [ posts(:featured_post), posts(:published_post) ]
  end

  test "digest lists each post with a read more link" do
    mail = DigestMailer.digest(@subscriber, @posts.map(&:id))

    assert_equal [ @subscriber.email ], mail.to
    assert_equal "2 new posts from #{SiteSetting.current.site_name}", mail.subject
    @posts.each do |post|
      assert_includes mail.html_part.body.to_s, post.title
      assert_includes mail.html_part.body.to_s, "/posts/#{post.slug}\""
      assert_match %r{/posts/#{post.slug}$}, mail.text_part.body.to_s
    end
    assert_includes mail.html_part.body.to_s, "Read more"
  end

  test "digest uses a singular subject for one post" do
    mail = DigestMailer.digest(@subscriber, [ @posts.first.id ])

    assert_equal "1 new post from #{SiteSetting.current.site_name}", mail.subject
  end

  test "digest includes the post excerpt" do
    post = @posts.first
    mail = DigestMailer.digest(@subscriber, [ post.id ])

    assert_includes mail.text_part.body.to_s, post.seo_description
  end

  test "digest links to the rest of the posts when the list was capped" do
    mail = DigestMailer.digest(@subscriber, [ @posts.first.id ], 5)

    assert_equal "5 new posts from #{SiteSetting.current.site_name}", mail.subject
    assert_includes mail.html_part.body.to_s, "See 4 more posts"
  end

  test "digest includes the featured image" do
    @posts.first.featured_image.attach(io: File.open(Rails.root.join("public/icon.png")), filename: "cover.png", content_type: "image/png")

    mail = DigestMailer.digest(@subscriber, [ @posts.first.id ])

    assert_match %r{<img src="http://[^"]+/rails/active_storage/[^"]+cover\.png"}, mail.html_part.body.to_s
  end

  test "digest includes unsubscribe and email preferences links" do
    mail = DigestMailer.digest(@subscriber, @posts.map(&:id))

    assert_match %r{/unsubscribe\?token=}, mail.html_part.body.to_s
    assert_match %r{/email-preferences\?token=}, mail.html_part.body.to_s
    assert_match %r{/email-preferences\?token=}, mail.text_part.body.to_s
    assert_equal "List-Unsubscribe=One-Click", mail["List-Unsubscribe-Post"].value
  end

  test "digest uses branding colors" do
    SiteSetting.current.update!(email_accent_color: "#ee1122", email_heading_color: "#aabbcc")

    mail = DigestMailer.digest(@subscriber, @posts.map(&:id))

    assert_includes mail.html_part.body.to_s, "#ee1122"
    assert_includes mail.html_part.body.to_s, "#aabbcc"
  end

  test "digest is not sent to a subscriber who unsubscribed after it was queued" do
    @subscriber.update!(unsubscribed_at: Time.current)

    assert_emails 0 do
      DigestMailer.digest(@subscriber, @posts.map(&:id)).deliver_now
    end
  end

  test "digest is not sent when its posts were unpublished after it was queued" do
    assert_emails 0 do
      DigestMailer.digest(@subscriber, [ posts(:draft_post).id ]).deliver_now
    end
  end
end
