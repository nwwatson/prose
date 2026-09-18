require "test_helper"

class Imports::GhostImporterTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  class FakeDownloader
    attr_reader :created_blobs, :failures, :requested

    def initialize
      @created_blobs = []
      @failures = []
      @requested = []
    end

    def download(url)
      @requested << url
      unless url.start_with?("https://")
        @failures << { url: url }
        return nil
      end

      blob = ActiveStorage::Blob.create_and_upload!(io: StringIO.new("GIF89a"), filename: File.basename(url), content_type: "image/gif")
      @created_blobs << blob
      blob
    end
  end

  test "imports posts with status, visibility, featured, excerpt, meta and media" do
    stats = run_import(site_url: "https://blog.example.com")

    post = Post.find_by!(slug: "ghost-cards")
    assert post.published?
    assert post.visibility_paid_only?
    assert post.featured
    assert_equal Time.utc(2024, 1, 10, 12), post.published_at
    assert_equal "A tour of every card", post.subtitle
    assert_equal "Meta from posts_meta", post.meta_description
    assert_equal users(:admin), post.user
    assert post.featured_image.attached?
    assert_equal 3, post.content.body.attachables.grep(ActiveStorage::Blob).size
    assert_includes post.content.body.to_html, "https://blog.example.com/other-post/"

    assert_equal 5, stats["posts_imported"]
    assert_equal 1, stats["pages_imported"]
    assert_equal 1, stats["skipped"]
  end

  test "maps the primary tag to the category and all public tags to tags" do
    run_import

    post = Post.find_by!(slug: "ghost-cards")
    assert_equal "Guides", post.category.name
    assert_equal %w[Ghost Guides], post.tags.map(&:name).sort
    assert_not Tag.exists?(name: "#hidden")
  end

  test "maps statuses and visibilities" do
    stats = run_import

    mobiledoc = Post.find_by!(slug: "mobiledoc-only")
    assert mobiledoc.draft?
    assert mobiledoc.visibility_members_only?
    assert_includes mobiledoc.content.body.to_html, "Mobiledoc heading"

    sent = Post.find_by!(slug: "email-only")
    assert sent.draft?
    assert_nil sent.published_at
    assert_includes stats["warnings"], "Email Only: email-only (sent) post imported as a draft"

    assert Post.find_by!(slug: "later").scheduled?

    lexical = Post.find_by!(slug: "lexical-only")
    assert lexical.visibility_paid_only?
    assert_includes stats["warnings"], "Lexical Only: no HTML in export; imported plain text only"
  end

  test "imports pages and skips reserved slugs" do
    stats = run_import

    assert Page.find_by!(slug: "about").published?
    assert_not Page.exists?(slug: "tags")
    assert stats["warnings"].any? { |w| w.include?("\"tags\" is reserved") }
  end

  test "warns once when images need a site url that was not given" do
    stats = run_import

    assert_equal 1, stats["warnings"].count { |w| w.include?("No Ghost site URL") }
    assert_not Post.find_by!(slug: "ghost-cards").featured_image.attached?
    assert_equal 0, stats["media_downloaded"]
  end

  test "resolves placeholder image urls with the site url" do
    downloader = FakeDownloader.new
    run_import(site_url: "https://blog.example.com", downloader: downloader)

    assert_includes downloader.requested, "https://blog.example.com/content/images/2024/01/feature.jpg"
    assert downloader.requested.none? { |url| url.include?("__GHOST_URL__") }
  end

  test "is idempotent" do
    run_import
    counts = [ Post.count, Page.count, Category.count, Tag.count ]

    stats = run_import

    assert_equal counts, [ Post.count, Page.count, Category.count, Tag.count ]
    assert_equal 7, stats["skipped"]
  end

  test "an unexpected error on one item does not abort the import" do
    boom = Class.new(Imports::Ghost::ContentConverter) do
      def convert(html, title: nil)
        raise "boom" if title == "Mobiledoc Only"

        super
      end
    end

    stats = nil
    with_converter(boom) { stats = run_import }

    assert_equal 1, stats["failed"]
    assert_equal 4, stats["posts_imported"]
    assert Post.exists?(slug: "ghost-cards")
    assert_not Post.exists?(slug: "mobiledoc-only")
    assert stats["warnings"].any? { |w| w.include?("Could not import \"Mobiledoc Only\": RuntimeError: boom") }
  end

  test "a failure reading the export still fails the whole import" do
    assert_raises(Imports::Ghost::ExportParser::InvalidFile) do
      Imports::GhostImporter.new(io: StringIO.new("{}"), user: users(:admin), downloader: FakeDownloader.new).call
    end
  end

  test "does not notify subscribers, fire webhooks or create versions" do
    Webhook.create!(url: "https://hooks.example.com/prose", events: Webhook::EVENTS)

    assert_no_difference "PostVersion.count" do
      run_import(site_url: "https://blog.example.com")
    end
    assert_no_enqueued_jobs(only: [ SendPostNotificationsJob, DeliverWebhookJob ])
  end

  private

  def with_converter(klass)
    original = Imports::Ghost::ContentConverter
    Imports::Ghost.send(:remove_const, :ContentConverter)
    Imports::Ghost.const_set(:ContentConverter, klass)
    yield
  ensure
    Imports::Ghost.send(:remove_const, :ContentConverter)
    Imports::Ghost.const_set(:ContentConverter, original)
  end

  def run_import(site_url: nil, downloader: FakeDownloader.new)
    Imports::GhostImporter.new(io: file_fixture("ghost.json").open("rb"), user: users(:admin), site_url: site_url, downloader: downloader).call
  end
end
