module ApplicationHelper
  def author_link(user, **options)
    identity = user.identity
    if identity.handle.present?
      link_to identity.name, author_path(identity, handle: identity.handle),
        class: options.delete(:class) || "text-charcoal hover:text-ink-blue transition-colors",
        **options
    else
      content_tag(:span, identity.name, **options)
    end
  end
end
