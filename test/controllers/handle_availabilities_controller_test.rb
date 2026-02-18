require "test_helper"

class HandleAvailabilitiesControllerTest < ActionDispatch::IntegrationTest
  test "GET show returns available for unused handle" do
    get handle_availability_path(handle: "newhandle", format: :json)
    assert_response :success
    json = JSON.parse(response.body)
    assert json["available"]
  end

  test "GET show returns unavailable for taken handle" do
    get handle_availability_path(handle: "subscriber1", format: :json)
    assert_response :success
    json = JSON.parse(response.body)
    assert_not json["available"]
  end

  test "GET show returns unavailable for short handle" do
    get handle_availability_path(handle: "ab", format: :json)
    assert_response :success
    json = JSON.parse(response.body)
    assert_not json["available"]
  end
end
