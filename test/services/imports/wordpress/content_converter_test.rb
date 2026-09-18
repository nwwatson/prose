require "test_helper"

class Imports::Wordpress::ContentConverterTest < ActiveSupport::TestCase
  class FakeDownloader
    attr_reader :requested

    def initialize(fail_for: [])
      @fail_for = fail_for
      @requested = []
    end

    def download(url)
      @requested << url
      return nil if @fail_for.any? { |fragment| url.include?(fragment) }

      ActiveStorage::Blob.create_and_upload!(io: StringIO.new("GIF89a"), filename: File.basename(url), content_type: "image/gif")
    end
  end

  setup do
    @warnings = []
    @downloader = FakeDownloader.new(fail_for: [ "broken" ])
    @converter = Imports::Wordpress::ContentConverter.new(
      downloader: @downloader, site_url: "https://wp.example.com", warn: ->(message) { @warnings << message }
    )
  end

  test "strips gutenberg block comments without adding paragraphs" do
    html = convert("<!-- wp:paragraph -->\n<p>One</p>\n<!-- /wp:paragraph -->\n\n<!-- wp:heading --><h2>Two</h2><!-- /wp:heading -->")

    assert_not_includes html, "wp:"
    assert_includes html, "<p>One</p>"
    assert_includes html, "<h2>Two</h2>"
  end

  test "adds paragraphs and line breaks to classic content" do
    html = convert("Line one\nline two\n\nSecond paragraph\n\n<h2>Heading</h2>")

    assert_includes html, "<p>Line one<br>\nline two</p>"
    assert_includes html, "<p>Second paragraph</p>"
    assert_includes html, "<h2>Heading</h2>"
    assert_not_includes html, "<p><h2>"
  end

  test "keeps blank lines inside pre blocks" do
    html = convert("<pre>a\n\nb</pre>\n\nafter")
    assert_includes html, "<pre>a\n\nb</pre>"
    assert_includes html, "<p>after</p>"
  end

  test "converts caption shortcodes into attachments with captions" do
    html = convert(%([caption id="attachment_5" width="300"]<img src="https://wp.example.com/cat.jpg" alt="cat" /> A sleepy cat[/caption]))

    assert_includes html, "<action-text-attachment"
    assert_includes html, %(caption="A sleepy cat")
    assert_not_includes html, "[caption"
  end

  test "converts embed and youtube shortcodes to links" do
    html = convert("[embed]https://www.youtube.com/watch?v=abc[/embed]\n\n[youtube=https://www.youtube.com/watch?v=xyz&w=640]")

    assert_includes html, %(<a href="https://www.youtube.com/watch?v=abc">)
    assert_includes html, %(<a href="https://www.youtube.com/watch?v=xyz">)
  end

  test "removes media shortcodes with a warning" do
    html = convert(%(Before\n\n[gallery ids="1,2"]\n\n[audio src="a.mp3"][/audio]\n\nAfter))

    assert_not_includes html, "[gallery"
    assert_not_includes html, "[audio"
    assert_includes @warnings, "Post: Removed unsupported [gallery] shortcode"
    assert_includes @warnings, "Post: Removed unsupported [audio] shortcode"
  end

  test "leaves unknown shortcodes as text and warns" do
    html = convert("He said [sic] and [custom_widget id=\"4\"].")

    assert_includes html, "[sic]"
    assert_includes html, %([custom_widget id="4"])
    assert_includes @warnings, "Post: Left unrecognized shortcode [custom_widget] as text"
  end

  test "does not treat footnote markers as shortcodes" do
    convert("A claim[1] and another[2].")
    assert_empty @warnings
  end

  test "removes scripts, styles and event handler attributes" do
    html = convert(%(<p onclick="evil()" class="x" style="color:red">Hi</p><script>alert(1)</script><style>p{}</style>))

    assert_equal "<p>Hi</p>", html
  end

  test "turns video iframes into links and drops other iframes" do
    html = convert(%(<figure><iframe src="https://www.youtube.com/embed/vid1"></iframe></figure>\n<p>Watch <iframe src="https://player.vimeo.com/video/42"></iframe></p>\n<iframe src="https://ads.example.com/x"></iframe>))

    assert_includes html, %(<a href="https://www.youtube.com/watch?v=vid1">)
    assert_includes html, %(<p>Watch <a href="https://vimeo.com/42">)
    assert_not_includes html, "iframe"
    assert @warnings.any? { |w| w.include?("Removed embedded iframe") }
  end

  test "converts gutenberg embed figures to links" do
    html = convert(%(<!-- wp:embed --><figure class="wp-block-embed"><div class="wp-block-embed__wrapper">\nhttps://twitter.com/prose/status/1\n</div></figure><!-- /wp:embed -->))
    assert_includes html, %(<p><a href="https://twitter.com/prose/status/1">)
  end

  test "downloads images, prefers the linked full-size file and resolves relative urls" do
    html = convert(%(<p><a href="/uploads/photo.jpg"><img src="/uploads/photo-300x200.jpg"></a></p>))

    assert_equal "https://wp.example.com/uploads/photo.jpg", @downloader.requested.first
    assert_includes html, "<action-text-attachment"
    assert_not_includes html, "<img"
  end

  test "uses figcaption as the attachment caption" do
    html = convert(%(<!-- wp:image --><figure><img src="https://wp.example.com/a.png"><figcaption>Caption here</figcaption></figure><!-- /wp:image -->))

    assert_includes html, %(caption="Caption here")
    assert_not_includes html, "<figcaption"
  end

  test "keeps every image of a figure holding several images" do
    html = convert(%(<!-- wp:html --><figure><img src="https://wp.example.com/one.png"><img src="https://wp.example.com/two.png"><figcaption>Pair</figcaption></figure><!-- /wp:html -->))

    assert_equal 2, html.scan("<action-text-attachment").size
    assert_not_includes html, "<img"
  end

  test "keeps every image of a gutenberg gallery block" do
    html = convert(<<~HTML)
      <!-- wp:gallery --><figure class="wp-block-gallery has-nested-images"><!-- wp:image --><figure class="wp-block-image"><img src="https://wp.example.com/a.png"></figure><!-- /wp:image --><!-- wp:image --><figure class="wp-block-image"><img src="https://wp.example.com/b.png"><figcaption>B</figcaption></figure><!-- /wp:image --></figure><!-- /wp:gallery -->
    HTML

    assert_equal 2, html.scan("<action-text-attachment").size
    assert_includes html, %(caption="B")
  end

  test "keeps the remote image when download fails" do
    html = convert(%(<p><img src="https://wp.example.com/broken.png" alt="x"></p>))

    assert_includes html, %(<img src="https://wp.example.com/broken.png" alt="x">)
    assert @warnings.any? { |w| w.include?("download failed") }
  end

  private

  def convert(html)
    @converter.convert(html, title: "Post")
  end
end
