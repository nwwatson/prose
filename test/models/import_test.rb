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
    assert_includes import.errors[:file], I18n.t("activerecord.errors.models.import.attributes.file.invalid_type")
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

  test "importer_for resolves wordpress and rejects unknown sources" do
    assert_equal Imports::WordpressImporter, Import.importer_for(:wordpress)
    assert_raises(ArgumentError) { Import.importer_for(:ghost) }
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

  def build_import(filename: "wordpress.xml", content_type: "application/xml")
    import = Import.new(user: users(:admin), source: :wordpress)
    import.file.attach(io: StringIO.new("<rss/>"), filename: filename, content_type: content_type)
    import
  end
end
