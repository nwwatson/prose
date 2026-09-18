require "test_helper"
require_relative "../../test_helpers/substack_export_helper"

class Imports::SubstackImporterTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper
  include ActionMailer::TestHelper
  include SubstackExportHelper

  class FakeDownloader
    attr_reader :created_blobs, :failures

    def initialize
      @created_blobs = []
      @failures = []
    end

    def download(url)
      blob = ActiveStorage::Blob.create_and_upload!(io: StringIO.new("GIF89a"), filename: File.basename(URI(url).path), content_type: "image/gif")
      @created_blobs << blob
      blob
    end
  end

  test "imports posts with status, visibility, subtitle and inline images" do
    stats = run_import

    first = Post.find_by!(slug: "first-issue")
    assert first.published?
    assert first.visibility_public?
    assert_equal "Welcome aboard", first.subtitle
    assert_equal Time.utc(2024, 3, 1, 15), first.published_at
    assert_equal users(:admin), first.user
    assert_equal 1, first.content.body.attachables.grep(ActiveStorage::Blob).size

    assert Post.find_by!(slug: "paid-deep-dive").visibility_paid_only?
    assert Post.find_by!(slug: "free-members").visibility_members_only?
    assert Post.find_by!(slug: "episode-one").visibility_paid_only?

    draft = Post.find_by!(slug: "draft-idea")
    assert draft.draft?
    assert_nil draft.published_at

    assert_equal 5, stats["posts_imported"]
    assert_equal 2, stats["skipped"]
    assert_equal 1, stats["media_downloaded"]
  end

  test "skips threads and posts without a body, and warns about podcasts" do
    stats = run_import

    assert_not Post.exists?(slug: "a-thread")
    assert_not Post.exists?(slug: "missing-body")
    assert_includes stats["warnings"], "Skipped \"Missing Body\": no post body found in the export"
    assert_includes stats["warnings"], "Episode One: podcast audio was not imported, only the show notes"
  end

  test "imports subscribers as confirmed with their original signup date" do
    stats = run_import

    reader = Subscriber.find_by!(email: "reader.one@example.com")
    assert reader.confirmed?
    assert_not reader.unsubscribed?
    assert_equal Time.utc(2023, 1, 15, 10), reader.confirmed_at
    assert_equal Time.utc(2023, 1, 15, 10), reader.created_at
    assert_equal "reader.one", reader.identity.name

    assert Subscriber.find_by!(email: "gone@example.com").unsubscribed?

    assert_equal 4, stats["subscribers_imported"]
    assert_equal 2, stats["subscribers_skipped"], "existing subscriber and invalid email"
    assert_includes stats["warnings"], "Skipped invalid subscriber email \"not-an-email\""
  end

  test "labels paid and comp subscribers" do
    run_import

    assert_equal [ "Substack paid" ], Subscriber.find_by!(email: "paid@example.com").subscriber_labels.map(&:name)
    assert_equal [ "Substack comp" ], Subscriber.find_by!(email: "comp@example.com").subscriber_labels.map(&:name)
    assert_empty Subscriber.find_by!(email: "reader.one@example.com").subscriber_labels
    assert_equal 1, SubscriberLabel.where(name: "Substack paid").count
  end

  test "reuses an existing label regardless of case" do
    label = SubscriberLabel.create!(name: "substack PAID", color: "#000000")

    run_import

    assert_equal 1, SubscriberLabel.where("LOWER(name) = ?", "substack paid").count
    assert_includes Subscriber.find_by!(email: "paid@example.com").subscriber_labels, label
  end

  test "does not touch existing subscribers" do
    existing = subscribers(:confirmed)

    assert_no_changes -> { existing.reload.attributes } do
      run_import
    end
  end

  test "imports subscribers from a bare csv" do
    stats = run_import(content: file_fixture("substack/email_list.example.csv").binread)

    assert_equal 4, stats["subscribers_imported"]
    assert_equal 0, stats["posts_imported"].to_i
  end

  test "sends no email, fires no webhooks and notifies no one" do
    Webhook.create!(url: "https://hooks.example.com/prose", events: Webhook::EVENTS)

    assert_no_emails do
      run_import
    end
    assert_no_enqueued_jobs(only: [ SendPostNotificationsJob, DeliverWebhookJob, ActionMailer::MailDeliveryJob ])
  end

  test "an unexpected error on one post does not abort the import" do
    boom = Class.new(Imports::Substack::ContentConverter) do
      def convert(html, title: nil)
        raise "boom" if title == "Paid Deep Dive"

        super
      end
    end

    stats = nil
    with_converter(boom) { stats = run_import }

    assert_equal 1, stats["failed"]
    assert_equal 4, stats["posts_imported"]
    assert_equal 4, stats["subscribers_imported"], "subscribers still import after a failed post"
    assert_not Post.exists?(slug: "paid-deep-dive")
    assert stats["warnings"].any? { |w| w.include?("Could not import \"Paid Deep Dive\": RuntimeError: boom") }
  end

  test "an unexpected error on one subscriber row does not abort the batch" do
    original_new = Subscriber.method(:new)
    Subscriber.define_singleton_method(:new) do |*args, **kwargs, &block|
      raise "database is locked" if kwargs[:email] == "comp@example.com"

      original_new.call(*args, **kwargs, &block)
    end

    stats = run_import

    assert_equal 3, stats["subscribers_imported"]
    assert_equal 3, stats["subscribers_skipped"]
    assert Subscriber.exists?(email: "paid@example.com")
    assert Subscriber.exists?(email: "gone@example.com"), "rows after the failure still import"
    assert_not Subscriber.exists?(email: "comp@example.com")
    assert stats["warnings"].any? { |w| w.include?("Skipped subscriber comp@example.com: RuntimeError: database is locked") }
  ensure
    Subscriber.singleton_class.send(:remove_method, :new)
  end

  test "a failure reading the export still fails the whole import" do
    assert_raises(Imports::Substack::ExportReader::InvalidFile) do
      run_import(content: "name\nbob\n")
    end
  end

  test "is idempotent" do
    run_import
    counts = [ Post.count, Subscriber.count, SubscriberLabel.count, SubscriberLabeling.count ]

    stats = run_import

    assert_equal counts, [ Post.count, Subscriber.count, SubscriberLabel.count, SubscriberLabeling.count ]
    assert_equal 7, stats["skipped"]
    assert_equal 6, stats["subscribers_skipped"]
    assert stats["warnings"].none? { |w| w.include?("podcast") }
  end

  private

  def with_converter(klass)
    original = Imports::Substack::ContentConverter
    Imports::Substack.send(:remove_const, :ContentConverter)
    Imports::Substack.const_set(:ContentConverter, klass)
    yield
  ensure
    Imports::Substack.send(:remove_const, :ContentConverter)
    Imports::Substack.const_set(:ContentConverter, original)
  end

  def run_import(content: substack_export_zip)
    Imports::SubstackImporter.new(io: StringIO.new(content), user: users(:admin), downloader: FakeDownloader.new).call
  end
end
