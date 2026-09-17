require "test_helper"

class Imports::WordpressImporterTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  class FakeDownloader
    attr_reader :created_blobs, :failures

    def initialize(fail_all: false)
      @fail_all = fail_all
      @created_blobs = []
      @failures = []
    end

    def download(url)
      if @fail_all
        @failures << { url: url }
        return nil
      end

      blob = ActiveStorage::Blob.create_and_upload!(io: StringIO.new("GIF89a"), filename: File.basename(url), content_type: "image/gif")
      @created_blobs << blob
      blob
    end
  end

  test "imports posts with mapped status, taxonomy, excerpt and media" do
    stats = run_import

    post = Post.find_by!(slug: "hello-welcome")
    assert_equal "Hello & Welcome", post.title
    assert post.published?
    assert_equal Time.utc(2024, 1, 15, 14, 30), post.published_at
    assert_equal users(:admin), post.user
    assert_equal "Travel", post.category.name
    assert_equal %w[Europe Food], post.tags.map(&:name).sort
    assert_equal "A short summary of the post.", post.meta_description
    assert post.featured_image.attached?
    assert_equal 1, post.content.body.attachables.grep(ActiveStorage::Blob).size
    assert_includes post.body_plain, "First paragraph"

    assert_equal 3, stats["posts_imported"]
    assert_equal 1, stats["pages_imported"]
    assert_equal 2, stats["skipped"]
    assert_equal 3, stats["media_downloaded"]
  end

  test "maps draft, future and trash statuses" do
    run_import

    draft = Post.find_by!(slug: "classic-draft")
    assert draft.draft?
    assert_nil draft.published_at
    assert_nil draft.category, "uncategorized should not become a category"

    assert Post.find_by!(slug: "future-post").scheduled?
    assert_not Post.exists?(slug: "trashed")
  end

  test "publishes future posts whose date has already passed" do
    xml = file_fixture("wordpress.xml").read.sub("2099-06-01 12:00:00", "2020-06-01 12:00:00")
    run_import(io: StringIO.new(xml))

    assert Post.find_by!(slug: "future-post").published?
  end

  test "imports pages and skips reserved slugs" do
    stats = run_import

    page = Page.find_by!(slug: "about-me")
    assert page.published?
    assert_equal 3, page.position
    assert_not Page.exists?(slug: "feed")
    assert stats["warnings"].any? { |w| w.include?("\"feed\" is reserved") }
  end

  test "reuses existing categories and tags" do
    category = Category.create!(name: "Travel", slug: "travel")
    tag = Tag.create!(name: "Europe", slug: "europe")

    assert_no_difference -> { Category.where(slug: "travel").count } do
      run_import
    end
    post = Post.find_by!(slug: "hello-welcome")
    assert_equal category, post.category
    assert_includes post.tags, tag
  end

  test "skips items whose slug already exists and is idempotent" do
    run_import
    counts = [ Post.count, Page.count, Category.count, Tag.count ]

    stats = run_import

    assert_equal counts, [ Post.count, Page.count, Category.count, Tag.count ]
    assert_equal 0, stats["posts_imported"].to_i
    assert_equal 0, stats["media_downloaded"]
    assert_equal 6, stats["skipped"]
  end

  test "does not notify subscribers, fire webhooks or create versions" do
    Webhook.create!(url: "https://hooks.example.com/prose", events: Webhook::EVENTS)

    assert_no_difference "PostVersion.count" do
      run_import
    end
    assert_no_enqueued_jobs(only: [ SendPostNotificationsJob, DeliverWebhookJob ])
  end

  test "keeps going when media downloads fail" do
    stats = run_import(downloader: FakeDownloader.new(fail_all: true))

    post = Post.find_by!(slug: "hello-welcome")
    assert_not post.featured_image.attached?
    assert_includes post.content.body.to_html, "https://wp.example.com/wp-content/uploads/2024/01/inline.png"
    assert_equal 3, stats["media_failed"]
    assert_equal 3, stats["posts_imported"]
  end

  test "records per-item failures without aborting the import" do
    original_new = Post.method(:new)
    Post.define_singleton_method(:new) do |*args, **kwargs, &block|
      original_new.call(*args, **kwargs, &block).tap do |post|
        next unless post.slug == "future-post"

        post.define_singleton_method(:valid?) do |*|
          errors.add(:base, "nope")
          false
        end
      end
    end

    stats = run_import

    assert_equal 1, stats["failed"]
    assert_equal 2, stats["posts_imported"]
    assert_not Post.exists?(slug: "future-post")
    assert stats["warnings"].any? { |w| w.include?("Could not import \"Future Post\": nope") }
  ensure
    Post.singleton_class.send(:remove_method, :new)
  end

  test "purges downloaded blobs that ended up unused" do
    downloader = FakeDownloader.new
    orphan = ActiveStorage::Blob.create_and_upload!(io: StringIO.new("GIF89a"), filename: "orphan.gif", content_type: "image/gif")
    downloader.created_blobs << orphan

    assert_enqueued_with(job: ActiveStorage::PurgeJob, args: [ orphan ]) do
      run_import(downloader: downloader)
    end
  end

  test "caps stored warnings" do
    importer = Imports::WordpressImporter.new(io: file_fixture("wordpress.xml").open, user: users(:admin), downloader: FakeDownloader.new)
    (Import::MAX_WARNINGS + 5).times { |i| importer.send(:warn, "warning #{i}") }

    result = importer.result
    assert_equal Import::MAX_WARNINGS, result["warnings"].size
    assert_equal 5, result["warnings_truncated"]
  end

  private

  def run_import(io: file_fixture("wordpress.xml").open, downloader: FakeDownloader.new)
    Imports::WordpressImporter.new(io: io, user: users(:admin), downloader: downloader).call
  end
end
