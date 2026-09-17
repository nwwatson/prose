require "test_helper"

class Admin::ExportDownloadsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @export = exports(:completed_json)
    @export.file.attach(io: StringIO.new('{"format":"prose"}'), filename: @export.download_filename, content_type: "application/json")
  end

  test "admins download the file as an attachment" do
    sign_in_as(:admin)
    get admin_export_download_path(@export)

    assert_response :success
    assert_equal '{"format":"prose"}', response.body
    assert_match(/attachment/, response.headers["Content-Disposition"])
    assert_match(@export.download_filename, response.headers["Content-Disposition"])
  end

  test "exports that are not completed are not downloadable" do
    sign_in_as(:admin)
    get admin_export_download_path(exports(:pending_markdown))

    assert_response :not_found
  end

  test "completed exports without a file redirect with an alert" do
    @export.file.purge
    sign_in_as(:admin)
    get admin_export_download_path(@export)

    assert_redirected_to admin_exports_path
  end

  test "writers cannot download exports" do
    sign_in_as(:writer)
    get admin_export_download_path(@export)

    assert_redirected_to admin_root_path
  end
end
