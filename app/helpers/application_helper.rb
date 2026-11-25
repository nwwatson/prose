module ApplicationHelper
  def author_link(user, **options)
    identity = user.identity
    if identity.handle.present?
      link_to identity.name, author_path(handle: identity.handle),
        class: options.delete(:class) || "text-link",
        **options
    else
      content_tag(:span, identity.name, **options)
    end
  end

  # "3 days ago" in the site locale, or +never+ when there is no time yet.
  def time_ago(time, never: t("shared.never"))
    return never if time.nil?

    t("shared.time_ago", time: time_ago_in_words(time))
  end

  def published_on(record, **html_options)
    content_tag(:time, l(record.published_at.to_date, format: :long),
      datetime: record.published_at.iso8601, **html_options)
  end
end
