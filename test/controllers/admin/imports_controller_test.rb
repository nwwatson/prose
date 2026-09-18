require "test_helper"

class Admin::ImportsControllerTest < ActionDispatch::IntegrationTest
  include ActiveJob::TestHelper

  test "GET index shows the upload form and recent imports" do
    sign_in_as(:admin)
    get admin_imports_path

    assert_response :success
    assert_select "form[action=?] input[type=file]", admin_imports_path
    assert_select "##{ActionView::RecordIdentifier.dom_id(imports(:completed_wordpress))}"
    assert_select "details summary", text: I18n.t("admin.imports.index.warnings", count: 1)
  end

  test "GET index shows empty state" do
    Import.delete_all
    sign_in_as(:admin)
    get admin_imports_path

    assert_select "p", text: I18n.t("admin.imports.index.no_imports")
  end

  test "POST create stores the file and queues the import" do
    sign_in_as(:admin)

    assert_difference "Import.count", 1 do
      assert_enqueued_with(job: ImportJob) do
        post admin_imports_path, params: { import: { source: "wordpress", file: fixture_file_upload("wordpress.xml", "application/xml") } }
      end
    end

    import = Import.recent.first
    assert import.source_wordpress?
    assert import.pending?
    assert import.file.attached?
    assert_equal users(:admin), import.user
    assert_redirected_to admin_imports_path
  end

  test "POST create without a file re-renders with errors" do
    sign_in_as(:admin)

    assert_no_difference "Import.count" do
      post admin_imports_path, params: { import: { source: "wordpress" } }
    end
    assert_response :unprocessable_entity
    assert_no_enqueued_jobs(only: ImportJob)
  end

  test "POST create rejects non-xml uploads" do
    sign_in_as(:admin)
    upload = Rack::Test::UploadedFile.new(StringIO.new("hello"), "text/plain", original_filename: "notes.txt")

    assert_no_difference "Import.count" do
      post admin_imports_path, params: { import: { source: "wordpress", file: upload } }
    end
    assert_response :unprocessable_entity
  end

  test "DELETE destroy removes the import record" do
    sign_in_as(:admin)

    assert_difference "Import.count", -1 do
      delete admin_import_path(imports(:completed_wordpress))
    end
    assert_redirected_to admin_imports_path
  end

  test "writers cannot access imports" do
    sign_in_as(:writer)

    get admin_imports_path
    assert_redirected_to admin_root_path

    assert_no_difference "Import.count" do
      post admin_imports_path, params: { import: { source: "wordpress", file: fixture_file_upload("wordpress.xml", "application/xml") } }
    end
    assert_redirected_to admin_root_path
  end

  test "exports page links to imports" do
    sign_in_as(:admin)
    get admin_exports_path

    assert_select "nav a[href=?]", admin_imports_path
  end
end
