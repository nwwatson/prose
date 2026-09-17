require "test_helper"

class Admin::ExportsControllerTest < ActionDispatch::IntegrationTest
  include ActiveJob::TestHelper

  test "GET index lists exports for admins" do
    sign_in_as(:admin)
    get admin_exports_path

    assert_response :success
    assert_select "##{ActionView::RecordIdentifier.dom_id(exports(:completed_json))}"
  end

  test "GET index shows empty state when there are no exports" do
    Export.delete_all
    sign_in_as(:admin)
    get admin_exports_path

    assert_response :success
    assert_select "p", text: I18n.t("admin.exports.index.no_exports")
  end

  test "POST create queues a markdown export" do
    sign_in_as(:admin)

    assert_difference "Export.count", 1 do
      assert_enqueued_with(job: ExportJob) do
        post admin_exports_path, params: { format_type: "markdown" }
      end
    end

    export = Export.recent.first
    assert export.format_markdown?
    assert export.pending?
    assert_equal users(:admin), export.user
    assert_redirected_to admin_exports_path
  end

  test "POST create queues a json export" do
    sign_in_as(:admin)

    assert_difference "Export.count", 1 do
      post admin_exports_path, params: { format_type: "json" }
    end
    assert Export.recent.first.format_json?
  end

  test "POST create rejects unknown formats" do
    sign_in_as(:admin)

    assert_no_difference "Export.count" do
      assert_no_enqueued_jobs(only: ExportJob) do
        post admin_exports_path, params: { format_type: "csv" }
      end
    end
    assert_redirected_to admin_exports_path
    assert_equal I18n.t("flash.admin.exports.invalid_format"), flash[:alert]
  end

  test "DELETE destroy removes the export" do
    sign_in_as(:admin)

    assert_difference "Export.count", -1 do
      delete admin_export_path(exports(:completed_json))
    end
    assert_redirected_to admin_exports_path
  end

  test "writers cannot access exports" do
    sign_in_as(:writer)

    get admin_exports_path
    assert_redirected_to admin_root_path

    assert_no_difference "Export.count" do
      post admin_exports_path, params: { format_type: "json" }
    end
    assert_redirected_to admin_root_path

    assert_no_difference "Export.count" do
      delete admin_export_path(exports(:completed_json))
    end
  end

  test "unauthenticated users are redirected to sign in" do
    get admin_exports_path
    assert_response :redirect
    assert_not_equal admin_exports_path, URI(response.location).path
  end
end
