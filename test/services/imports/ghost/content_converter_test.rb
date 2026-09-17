require "test_helper"

class Imports::Ghost::ContentConverterTest < ActiveSupport::TestCase
  class FakeDownloader
    attr_reader :requested

    def initialize
      @requested = []
    end

    def download(url)
      @requested << url
      return nil unless url.start_with?("https://")

      ActiveStorage::Blob.create_and_upload!(io: StringIO.new("GIF89a"), filename: File.basename(url), content_type: "image/gif")
    end
  end

  setup do
    @warnings = []
    @downloader = FakeDownloader.new
  end

  test "replaces the __GHOST_URL__ placeholder with the site url" do
    html = convert(%(<p><a href="__GHOST_URL__/other-post/">link</a></p>), site_url: "https://blog.example.com/")
    assert_includes html, %(href="https://blog.example.com/other-post/")
  end

  test "removes the placeholder when no site url is given, and image downloads fail" do
    html = convert(%(<figure class="kg-card kg-image-card"><img src="__GHOST_URL__/content/images/a.png"></figure>))

    assert_includes html, %(<img src="/content/images/a.png">)
    assert_not_includes html, "__GHOST_URL__"
  end

  test "downloads the original image before the resized variant and keeps the caption" do
    html = convert(%(<figure class="kg-card kg-image-card kg-card-hascaption"><img src="__GHOST_URL__/content/images/size/w600/2024/01/photo.jpg" class="kg-image" srcset="x 600w"><figcaption>Caption</figcaption></figure>), site_url: "https://blog.example.com")

    assert_equal "https://blog.example.com/content/images/2024/01/photo.jpg", @downloader.requested.first
    assert_includes html, %(caption="Caption")
    assert_not_includes html, "kg-"
  end

  test "keeps every image of a gallery" do
    html = convert(%(<figure class="kg-card kg-gallery-card"><div class="kg-gallery-container"><div class="kg-gallery-row"><div class="kg-gallery-image"><img src="https://cdn.example.com/1.jpg"></div><div class="kg-gallery-image"><img src="https://cdn.example.com/2.jpg"></div></div></div></figure>))

    assert_equal 2, html.scan("<action-text-attachment").size
    assert_not_includes html, "<div"
  end

  test "converts bookmark, button and file cards to links" do
    html = convert(<<~HTML, site_url: "https://blog.example.com")
      <figure class="kg-card kg-bookmark-card"><a class="kg-bookmark-container" href="https://example.org/a"><div class="kg-bookmark-content"><div class="kg-bookmark-title">An article</div><div class="kg-bookmark-description">Desc</div></div></a></figure>
      <div class="kg-card kg-button-card"><a href="https://example.com/join" class="kg-btn">Join now</a></div>
      <div class="kg-card kg-file-card"><a class="kg-file-card-container" href="__GHOST_URL__/content/files/guide.pdf"><div class="kg-file-card-title">The guide</div></a></div>
    HTML

    assert_includes html, %(<p><a href="https://example.org/a">An article</a></p>)
    assert_includes html, %(<p><a href="https://example.com/join">Join now</a></p>)
    assert_includes html, %(<p><a href="https://blog.example.com/content/files/guide.pdf">The guide</a></p>)
  end

  test "converts callouts to blockquotes" do
    html = convert(%(<div class="kg-card kg-callout-card"><div class="kg-callout-emoji">💡</div><div class="kg-callout-text">A <b>tip</b></div></div>))
    assert_equal "<blockquote><p>💡 A <b>tip</b></p></blockquote>", html
  end

  test "turns embed card iframes into links and unwraps the card" do
    html = convert(%(<figure class="kg-card kg-embed-card"><iframe src="https://www.youtube.com/embed/abc?feature=oembed"></iframe></figure>))
    assert_equal %(<p><a href="https://www.youtube.com/watch?v=abc">https://www.youtube.com/watch?v=abc</a></p>), html
  end

  test "removes audio and video cards with a warning, and signup cards silently" do
    html = convert(<<~HTML)
      <div class="kg-card kg-audio-card"><audio src="a.mp3"></audio><div>Episode</div></div>
      <figure class="kg-card kg-video-card"><video src="v.mp4"></video></figure>
      <div class="kg-card kg-signup-card"><h2>Subscribe</h2></div>
      <p>Kept</p>
    HTML

    assert_equal "<p>Kept</p>", html
    assert_equal [ "Post: Removed unsupported audio card", "Post: Removed unsupported video card" ], @warnings
  end

  test "strips html card markers and unwraps unknown kg wrappers" do
    html = convert(%(<!--kg-card-begin: html--><p>Raw</p><!--kg-card-end: html--><div class="kg-card kg-toggle-card"><h4 class="kg-toggle-heading-text">Q</h4><div class="kg-toggle-content"><p>A</p></div></div>))

    assert_includes html, "<p>Raw</p>"
    assert_includes html, "<h4>Q</h4>"
    assert_includes html, "<p>A</p>"
    assert_not_includes html, "kg-"
    assert_not_includes html, "<!--"
  end

  private

  def convert(html, site_url: nil)
    Imports::Ghost::ContentConverter.new(downloader: @downloader, site_url: site_url, warn: ->(m) { @warnings << m })
      .convert(html, title: "Post").gsub(/\s*\n\s*/, "\n").strip
  end
end
