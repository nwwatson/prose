require "test_helper"

class ImportJobTest < ActiveJob::TestCase
  include ActionCable::TestHelper

  setup do
    # No network in tests: every media host "fails to resolve", so downloads
    # fail fast and the importer keeps the remote URLs.
    @original_resolve = Webhooks::UrlGuard.method(:resolve)
    Webhooks::UrlGuard.define_singleton_method(:resolve) { |_host| [] }
  end

  teardown do
    Webhooks::UrlGuard.define_singleton_method(:resolve, @original_resolve)
  end

  test "runs the importer and stores stats" do
    import = create_import(file_fixture("wordpress.xml").read)

    ImportJob.perform_now(import)

    import.reload
    assert import.completed?
    assert import.completed_at.present?
    assert_equal 3, import.stat(:posts_imported)
    assert_equal 1, import.stat(:pages_imported)
    assert_equal 3, import.stat(:media_failed)
    assert Post.exists?(slug: "hello-welcome")
  end

  test "marks the import failed for an invalid file" do
    import = create_import("<feed><entry/></feed>")

    ImportJob.perform_now(import)

    import.reload
    assert import.failed?
    assert_equal "Not a WordPress export file", import.error_message
  end

  test "broadcasts status changes to the imports stream" do
    import = create_import(file_fixture("wordpress.xml").read)

    assert_broadcasts("imports", 2) do
      ImportJob.perform_now(import)
    end
  end

  private

  def create_import(xml)
    import = Import.new(user: users(:admin), source: :wordpress)
    import.file.attach(io: StringIO.new(xml), filename: "export.xml", content_type: "application/xml")
    import.save!
    import
  end
end
