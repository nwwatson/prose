require "test_helper"

class RichTextFlattenerTest < ActiveSupport::TestCase
  setup do
    @image = ActiveStorage::Blob.create_and_upload!(io: StringIO.new("GIF89a"), filename: "cat.gif", content_type: "image/gif")
    @file = ActiveStorage::Blob.create_and_upload!(io: StringIO.new("notes"), filename: "a&b.txt", content_type: "text/plain")
    @x_post = XPost.create!(url: "https://x.com/prose/status/1", embed_html: "<blockquote>tweet</blockquote>")
    @video = YouTubeVideo.create!(url: "https://www.youtube.com/watch?v=dQw4w9WgXcQ", video_id: "dQw4w9WgXcQ")
  end

  test "flattens blobs and embeds to plain tags using the block's blob URL" do
    html = flatten(content(attachment(@image, caption: "A cat"), attachment(@file), attachment(@x_post), attachment(@video)), wrap: false)

    assert_equal [
      %(<img src="/files/cat.gif" alt="A cat">),
      %(<a href="/files/a&amp;b.txt">a&amp;b.txt</a>),
      %(<a href="#{@x_post.url}">#{@x_post.url}</a>),
      %(<a href="#{@video.url}">#{ERB::Util.html_escape(@video.url)}</a>)
    ].join, html
  end

  test "an uncaptioned image falls back to its filename for alt text" do
    assert_equal %(<img src="/files/cat.gif" alt="cat.gif">), flatten(content(attachment(@image)), wrap: false)
  end

  test "wrap puts each replacement in its own paragraph" do
    html = flatten(content(attachment(@image), attachment(@x_post)), wrap: true)

    assert_equal %(<p><img src="/files/cat.gif" alt="cat.gif"></p><p><a href="#{@x_post.url}">#{@x_post.url}</a></p>), html
  end

  test "an unresolvable attachment becomes its escaped text, wrapped only when it has some" do
    missing = %(<action-text-attachment sgid="gone" content-type="application/x-unknown" caption="a <b> c"></action-text-attachment>)
    text = ActionText::Content.new(missing).attachments.first.to_plain_text
    escaped = ERB::Util.html_escape(text).to_s

    assert_equal escaped, flatten(content(missing), wrap: false)
    assert_equal(text.present? ? "<p>#{escaped}</p>" : "", flatten(content(missing), wrap: true))
  end

  private

  def attachment(attachable, **options)
    ActionText::Attachment.from_attachable(attachable, **options).to_html
  end

  def content(*parts)
    ActionText::Content.new(parts.join)
  end

  def flatten(content, wrap:)
    RichTextFlattener.call(content, wrap: wrap) { |blob| "/files/#{blob.filename}" }
  end
end
