require "test_helper"

class ExportTest < ActiveSupport::TestCase
  test "defaults to pending status" do
    export = Export.create!(user: users(:admin), format: :json)
    assert export.pending?
  end

  test "rejects unknown formats as a validation error" do
    export = Export.new(user: users(:admin), format: "csv")
    assert_not export.valid?
    assert export.errors[:format].any?
  end

  test "exporter_for resolves each format and rejects unknown ones" do
    assert_equal Exports::MarkdownExporter, Export.exporter_for(:markdown)
    assert_equal Exports::JsonExporter, Export.exporter_for("json")
    assert_raises(ArgumentError) { Export.exporter_for("csv") }
  end

  test "file extension and content type follow the format" do
    assert_equal "zip", exports(:pending_markdown).file_extension
    assert_equal "application/zip", exports(:pending_markdown).content_type
    assert_equal "json", exports(:completed_json).file_extension
    assert_equal "application/json", exports(:completed_json).content_type
  end

  test "download_filename includes date, id and extension" do
    export = exports(:completed_json)
    assert_equal "prose-export-#{export.created_at.to_date.iso8601}-#{export.id}.json", export.download_filename
  end

  test "complete_with! attaches the file and marks completed" do
    export = exports(:pending_markdown)
    export.complete_with!(StringIO.new("zip-bytes"))

    assert export.reload.completed?
    assert export.completed_at.present?
    assert export.file.attached?
    assert_equal "application/zip", export.file.content_type
  end

  test "fail_with! records a truncated error message" do
    export = exports(:pending_markdown)
    export.fail_with!(RuntimeError.new("x" * 1000))

    assert export.reload.failed?
    assert_equal 500, export.error_message.length
  end

  test "prunes exports beyond the retention limit on create" do
    Export.delete_all
    oldest = Export.create!(user: users(:admin), format: :json, created_at: 2.days.ago)
    Export::RETENTION_LIMIT.times { |i| Export.create!(user: users(:admin), format: :json, created_at: i.minutes.ago) }

    assert_equal Export::RETENTION_LIMIT, Export.count
    assert_not Export.exists?(oldest.id)
  end
end
