module CommentsHelper
  ALLOWED_TAGS = %w[p strong em a code pre ul ol li blockquote br h1 h2 h3 del].freeze
  ALLOWED_ATTRIBUTES = %w[href title].freeze

  def sanitize_markdown(html)
    sanitized = sanitize(html, tags: ALLOWED_TAGS, attributes: ALLOWED_ATTRIBUTES)

    # Add rel and target attributes to links for safety
    sanitized.gsub(%r{<a\s}, '<a rel="nofollow noopener" target="_blank" ').html_safe
  end
end
