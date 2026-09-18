require "test_helper"

class Admin::MailingListsControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_as(:admin)
  end

  test "GET index lists mailing lists with subscriber counts" do
    get admin_mailing_lists_path

    assert_response :success
    assert_match "Deep Dives", response.body
    assert_match "Retired List", response.body
  end

  test "GET new renders the form" do
    get new_admin_mailing_list_path
    assert_response :success
  end

  test "POST create creates a list" do
    assert_difference "MailingList.count", 1 do
      post admin_mailing_lists_path, params: { mailing_list: { name: "Weekly Links", frequency: "Weekly", subscribe_by_default: "1" } }
    end

    list = MailingList.find_by!(slug: "weekly-links")
    assert list.subscribe_by_default?
    assert_redirected_to admin_mailing_lists_path
  end

  test "POST create with invalid data re-renders the form" do
    assert_no_difference "MailingList.count" do
      post admin_mailing_lists_path, params: { mailing_list: { name: "" } }
    end
    assert_response :unprocessable_entity
  end

  test "PATCH update updates a list" do
    patch admin_mailing_list_path(mailing_lists(:deep_dives)), params: { mailing_list: { active: "0" } }

    assert_redirected_to admin_mailing_lists_path
    assert_not mailing_lists(:deep_dives).reload.active?
  end

  test "DELETE destroy removes a list" do
    assert_difference "MailingList.count", -1 do
      delete admin_mailing_list_path(mailing_lists(:deep_dives))
    end
    assert_redirected_to admin_mailing_lists_path
  end

  test "writers can manage lists" do
    sign_in_as(:writer)

    get admin_mailing_lists_path
    assert_response :success
  end

  test "requires authentication" do
    delete admin_session_path
    get admin_mailing_lists_path
    assert_redirected_to new_admin_session_path
  end
end
