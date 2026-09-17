require "test_helper"

class Exports::MarkdownExporterTest < ActiveSupport::TestCase
  setup do
    @inline_blob = ActiveStorage::Blob.create_and_upload!(io: StringIO.new("GIF89a-inline"), filename: "cat photo.gif", content_type: "image/gif")
    @post = posts(:published_post)
    @post.update!(content: <<~HTML)
      <h2>Intro</h2>
      <p>Hello <strong>world</strong>.</p>
      #{ActionText::Attachment.from_attachable(@inline_blob, caption: "A cat").to_html}
      #{ActionText::Attachment.from_attachable(XPost.create!(url: "https://x.com/prose/status/1", embed_html: "<blockquote>tweet</blockquote>")).to_html}
    HTML
    @post.featured_image.attach(io: StringIO.new("GIF89a-featured"), filename: "hero.gif", content_type: "image/gif")
    pages(:published_page).update!(content: "<p>About us</p>")
  end

  test "writes a markdown file per post and page" do
    entries = read_zip

    Post.pluck(:slug).each { |slug| assert entries.key?("posts/#{slug}.md"), "missing post #{slug}" }
    Page.pluck(:slug).each { |slug| assert entries.key?("pages/#{slug}.md"), "missing page #{slug}" }
  end

  test "front matter carries post metadata" do
    front_matter, _body = split_document(read_zip.fetch("posts/#{@post.slug}.md"))

    assert_equal "Published Post", front_matter["title"]
    assert_equal "published", front_matter["status"]
    assert_equal "public", front_matter["visibility"]
    assert_equal @post.category.name, front_matter["category"]
    assert_equal @post.tags.map(&:name).sort, front_matter["tags"]
    assert_equal @post.published_at.iso8601, front_matter["published_at"]
    assert_equal "../images/#{@post.featured_image.blob.id}-hero.gif", front_matter["featured_image"]
  end

  test "converts rich text to markdown and rewrites attachments" do
    _front_matter, body = split_document(read_zip.fetch("posts/#{@post.slug}.md"))

    assert_includes body, "## Intro"
    assert_includes body, "Hello **world**."
    assert_includes body, "![A cat](../images/#{@inline_blob.id}-cat-photo.gif)"
    assert_includes body, "[https://x.com/prose/status/1](https://x.com/prose/status/1)"
    assert_not_includes body, "action-text-attachment"
  end

  test "bundles featured and inline images" do
    entries = read_zip

    assert_equal "GIF89a-inline", entries.fetch("images/#{@inline_blob.id}-cat-photo.gif")
    assert_equal "GIF89a-featured", entries.fetch("images/#{@post.featured_image.blob.id}-hero.gif")
  end

  test "includes drafts" do
    assert read_zip.key?("posts/#{posts(:draft_post).slug}.md")
  end

  test "page front matter and body" do
    front_matter, body = split_document(read_zip.fetch("pages/#{pages(:published_page).slug}.md"))

    assert_equal pages(:published_page).title, front_matter["title"]
    assert_equal "About us", body.strip
  end

  private

  def read_zip
    tempfile = Exports::MarkdownExporter.call
    entries = {}
    Zip::File.open(tempfile.path) do |zip|
      zip.each do |entry|
        content = entry.get_input_stream.read
        entries[entry.name] = entry.name.end_with?(".md") ? content.force_encoding(Encoding::UTF_8) : content
      end
    end
    entries
  ensure
    tempfile&.close!
  end

  def split_document(document)
    _, yaml, body = document.split(/^---\n/, 3)
    [ YAML.safe_load(yaml), body ]
  end
end
