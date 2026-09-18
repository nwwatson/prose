require "test_helper"

class Imports::Substack::ContentConverterTest < ActiveSupport::TestCase
  class FakeDownloader
    attr_reader :requested

    def initialize
      @requested = []
    end

    def download(url)
      @requested << url
      ActiveStorage::Blob.create_and_upload!(io: StringIO.new("GIF89a"), filename: File.basename(URI(url).path), content_type: "image/gif")
    end
  end

  setup do
    @downloader = FakeDownloader.new
    @warnings = []
  end

  test "converts the fixture post" do
    html = convert(file_fixture("substack/posts/101.first-issue.html").read)

    assert_includes html, "<p>Hello <strong>readers</strong>.</p>"
    assert_includes html, %(caption="The caption")
    assert_includes html, %(<a href="https://www.youtube.com/watch?v=abc123">)
    assert_includes html, %(<a href="https://twitter.com/someone/status/1">)
    assert_includes html, "<blockquote><p>A pull quote</p></blockquote>"
    assert_includes html, %(<a href="https://example.com/course">See the course</a>)
    assert_includes html, %(<a href="https://other.substack.com/p/older">An older post</a>)
    assert_includes html, "<p>After the paywall.</p>"

    %w[Subscribe subscription-widget paywall-jump <svg <picture <form <input data-attrs <iframe].each do |fragment|
      assert_not_includes html, fragment
    end
  end

  test "downloads the original image behind the substack cdn" do
    convert(%(<figure><img src="https://substackcdn.com/image/fetch/w_1456,c_limit,f_auto/https%3A%2F%2Fsubstack-post-media.s3.amazonaws.com%2Fpublic%2Fimages%2Fpic.png"></figure>))

    assert_equal [ "https://substack-post-media.s3.amazonaws.com/public/images/pic.png" ], @downloader.requested
  end

  test "removes subscribe and share buttons but keeps other buttons" do
    html = convert(<<~HTML)
      <p class="button-wrapper"><a class="button" href="https://pub.substack.com/subscribe?utm_source=x">Subscribe</a></p>
      <p class="button-wrapper"><a class="button" href="https://pub.substack.com/p/post?action=share">Share</a></p>
      <div class="captioned-button-wrap"><p class="button-wrapper"><a class="button" href="https://example.com/buy">Buy the book</a></p></div>
    HTML

    assert_equal %(<p><a href="https://example.com/buy">Buy the book</a></p>), html.strip
  end

  test "drops embeds whose data-attrs are missing or unsafe" do
    html = convert(%(<div class="tweet" data-attrs="not json"></div><div class="embedded-post-wrap" data-attrs='{"url":"javascript:alert(1)"}'></div><p>Kept</p>))
    assert_equal "<p>Kept</p>", html.strip
  end

  test "turns vimeo embeds into links" do
    html = convert(%(<div class="vimeo-wrap" data-attrs='{"videoId":"42"}'></div>))
    assert_includes html, %(<a href="https://vimeo.com/42">)
  end

  private

  def convert(html)
    Imports::Substack::ContentConverter.new(downloader: @downloader, warn: ->(m) { @warnings << m }).convert(html, title: "Post")
  end
end
