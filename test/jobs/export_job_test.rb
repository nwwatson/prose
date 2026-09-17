require "test_helper"

class ExportJobTest < ActiveJob::TestCase
  include ActionCable::TestHelper

  test "builds the export and attaches the file" do
    export = exports(:pending_markdown)

    ExportJob.perform_now(export)

    export.reload
    assert export.completed?
    assert export.file.attached?
    assert_equal "application/zip", export.file.content_type
    assert export.file.byte_size.positive?
  end

  test "attaches a JSON file for json exports" do
    export = Export.create!(user: users(:admin), format: :json)

    ExportJob.perform_now(export)

    assert export.reload.completed?
    assert_equal "prose", JSON.parse(export.file.download)["format"]
  end

  test "marks the export failed when the exporter raises" do
    export = exports(:pending_markdown)
    Exports::MarkdownExporter.singleton_class.alias_method(:original_call, :call)
    Exports::MarkdownExporter.define_singleton_method(:call) { raise "disk full" }

    ExportJob.perform_now(export)

    export.reload
    assert export.failed?
    assert_equal "disk full", export.error_message
    assert_not export.file.attached?
  ensure
    Exports::MarkdownExporter.singleton_class.alias_method(:call, :original_call)
    Exports::MarkdownExporter.singleton_class.remove_method(:original_call)
  end

  test "broadcasts status changes to the exports stream" do
    export = exports(:pending_markdown)

    assert_broadcasts("exports", 2) do
      ExportJob.perform_now(export)
    end
  end
end
