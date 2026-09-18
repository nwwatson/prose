class DigestMailer < ApplicationMailer
  FEATURED_IMAGE_WIDTH = 1072 # 2x the 536px content column, for retina screens

  helper_method :digest_featured_image_url

  # post_ids arrive newest first; total_count may exceed them when the job
  # capped the list, so the email can point at the rest of the archive.
  def digest(subscriber, post_ids, total_count = post_ids.size)
    return if subscriber.unsubscribed?

    @subscriber = subscriber
    @posts = Post.live.where(id: post_ids).with_author.with_attached_featured_image.by_publication_date.to_a
    return if @posts.empty? # unpublished since the digest was queued

    @total_count = total_count
    @unsubscribe_url = generate_unsubscribe_url(subscriber)
    @email_preferences_url = email_preferences_url(token: subscriber.email_preferences_token)
    load_email_branding

    set_list_unsubscribe_headers(@unsubscribe_url)

    mail(to: subscriber.email, subject: t("digest_mailer.digest.subject", count: total_count, site_name: @site_name))
  end

  private

  # Email clients can't render WebP, so the variant keeps the original format.
  def digest_featured_image_url(post)
    return unless post.featured_image.attached?

    image = post.featured_image
    image = image.variant(resize_to_limit: [ FEATURED_IMAGE_WIDTH, nil ]) if image.variable?
    polymorphic_url(image)
  end
end
