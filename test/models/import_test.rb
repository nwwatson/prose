require "test_helper"

class ImportTest < ActiveSupport::TestCase
  test "valid with an attached xml file" do
    assert build_import.valid?
  end

  test "requires a file" do
    import = Import.new(user: users(:admin), source: :wordpress)
    assert_not import.valid?
    assert import.errors[:file].any?
  end

  test "rejects non-xml files" do
    import = build_import(filename: "notes.txt", content_type: "text/plain")
    assert_not import.valid?
    assert_includes import.errors[:file], I18n.t("activerecord.errors.models.import.attributes.file.invalid_wordpress_type")
  end

  test "rejects files over the size limit" do
    import = build_import
    import.file.blob.byte_size = Import::MAX_FILE_SIZE + 1
    assert_not import.valid?
    assert import.errors.added?(:file, :too_large, count: Import::MAX_FILE_SIZE / 1.megabyte)
  end

  test "rejects unknown sources as a validation error" do
    import = build_import
    import.source = "joomla"
    assert_not import.valid?
    assert import.errors[:source].any?
  end

  test "importer_for resolves each source and rejects unknown ones" do
    assert_equal Imports::WordpressImporter, Import.importer_for(:wordpress)
    assert_equal Imports::GhostImporter, Import.importer_for(:ghost)
    assert_equal Imports::SubstackImporter, Import.importer_for(:substack)
    assert_raises(ArgumentError) { Import.importer_for(:medium) }
  end

  test "ghost imports require a json file" do
    assert build_import(source: :ghost, filename: "ghost.json", content_type: "application/json").valid?

    import = build_import(source: :ghost)
    assert_not import.valid?
    assert_includes import.errors[:file], I18n.t("activerecord.errors.models.import.attributes.file.invalid_ghost_type")
  end

  test "substack imports accept a zip or csv" do
    assert build_import(source: :substack, filename: "export.zip", content_type: "application/zip").valid?
    assert build_import(source: :substack, filename: "email_list.csv", content_type: "text/csv").valid?
    assert build_import(source: :substack, filename: "EMAIL_LIST.CSV", content_type: "application/octet-stream").valid?

    import = build_import(source: :substack, filename: "ghost.json", content_type: "application/json")
    assert_not import.valid?
    assert_includes import.errors[:file], I18n.t("activerecord.errors.models.import.attributes.file.invalid_substack_type")
  end

  test "site_url is optional, normalized and must be http(s)" do
    import = build_import(source: :ghost, filename: "ghost.json", content_type: "application/json")

    import.site_url = "  https://blog.example.com/  "
    assert import.valid?
    assert_equal "https://blog.example.com", import.site_url

    import.site_url = ""
    assert import.valid?
    assert_nil import.site_url

    %w[javascript:alert(1) ftp://example.com not\ a\ url].each do |bad|
      import.site_url = bad
      assert_not import.valid?, "expected #{bad} to be invalid"
    end
  end

  test "stat and warnings read from the stats json" do
    import = imports(:completed_wordpress)
    assert_equal 3, import.stat(:posts_imported)
    assert_equal 0, import.stat(:failed)
    assert_equal 1, import.warnings.size
  end

  test "complete_with! and fail_with! update status" do
    import = build_import
    import.save!

    import.complete_with!("posts_imported" => 2)
    assert import.reload.completed?
    assert_equal 2, import.stat(:posts_imported)

    import.fail_with!(RuntimeError.new("boom"))
    assert import.reload.failed?
    assert_equal "boom", import.error_message
  end

  private

  def build_import(source: :wordpress, filename: "wordpress.xml", content_type: "application/xml")
    import = Import.new(user: users(:admin), source: source)
    import.file.attach(io: StringIO.new("<rss/>"), filename: filename, content_type: content_type)
    import
  end
end
