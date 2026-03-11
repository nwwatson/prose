require "test_helper"

class Admin::SegmentsControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_as(:admin)
  end

  test "GET index lists segments" do
    get admin_segments_path
    assert_response :success
  end

  test "GET show renders segment" do
    get admin_segment_path(segments(:vip_segment))
    assert_response :success
  end

  test "GET new renders form" do
    get new_admin_segment_path
    assert_response :success
  end

  test "POST create creates segment" do
    assert_difference "Segment.count", 1 do
      post admin_segments_path, params: {
        segment: { name: "New Segment", description: "Test", label_ids: [], label_mode: "any_of" }
      }
    end
    assert_redirected_to admin_segments_path
  end

  test "POST create with invalid data renders form" do
    assert_no_difference "Segment.count" do
      post admin_segments_path, params: { segment: { name: "" } }
    end
    assert_response :unprocessable_entity
  end

  test "GET edit renders form" do
    get edit_admin_segment_path(segments(:vip_segment))
    assert_response :success
  end

  test "PATCH update updates segment" do
    segment = segments(:vip_segment)
    patch admin_segment_path(segment), params: {
      segment: { name: "Updated Segment", label_ids: [], label_mode: "any_of" }
    }
    assert_redirected_to admin_segments_path
    assert_equal "Updated Segment", segment.reload.name
  end

  test "DELETE destroy removes segment" do
    assert_difference "Segment.count", -1 do
      delete admin_segment_path(segments(:recent_segment))
    end
    assert_redirected_to admin_segments_path
  end

  test "GET count returns subscriber count" do
    get count_admin_segment_path(segments(:vip_segment))
    assert_response :success
  end

  test "requires authentication" do
    delete admin_session_path
    get admin_segments_path
    assert_redirected_to new_admin_session_path
  end
end
