# Renders rich text with its attachments flattened to plain <img>/<a> tags, for
# consumers that can't run our embed partials or Stimulus controllers (the
# Markdown export and ActivityPub). A new embed type is handled here once.
#
#   RichTextFlattener.call(rich_text.body, wrap: false) { |blob| url_for_blob(blob) }
#
# The block supplies each uploaded blob's URL. With +wrap+, every replacement is
# its own paragraph and an attachment with nothing to show leaves none behind.
class RichTextFlattener
  def self.call(content, wrap:, &blob_url)
    new(wrap: wrap, blob_url: blob_url).call(content)
  end

  def initialize(wrap:, blob_url:)
    @wrap = wrap
    @blob_url = blob_url
  end

  def call(content)
    content.render_attachments { |attachment| replacement_for(attachment) }.to_html
  end

  private

  def replacement_for(attachment)
    element = element_for(attachment)
    return element unless @wrap

    element.present? ? helpers.tag.p(element) : ""
  end

  def element_for(attachment)
    attachable = attachment.attachable

    case attachable
    when ActiveStorage::Blob
      blob_element(attachment, attachable)
    when XPost, YouTubeVideo
      helpers.link_to(attachable.url, attachable.url)
    else
      ERB::Util.html_escape(attachment.to_plain_text)
    end
  end

  def blob_element(attachment, blob)
    url = @blob_url.call(blob)
    return helpers.link_to(blob.filename.to_s, url) unless blob.image?

    helpers.tag.img(src: url, alt: attachment.caption.presence || blob.filename.to_s)
  end

  def helpers
    ActionController::Base.helpers
  end
end
