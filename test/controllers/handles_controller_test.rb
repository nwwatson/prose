require "test_helper"

class HandlesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @subscriber = subscribers(:confirmed)
  end

  test "redirects to root when not signed in" do
    patch "/handle", params: { handle: "new_handle" }

    assert_redirected_to "/"
    assert_equal "subscriber1", @subscriber.identity.reload.handle
  end

  test "html update normalizes the handle and redirects back" do
    sign_in_subscriber(@subscriber)

    patch "/handle", params: { handle: "  New_Handle " }, headers: { "HTTP_REFERER" => "http://www.example.com/reading-list" }

    assert_redirected_to "http://www.example.com/reading-list"
    assert_equal "Handle updated.", flash[:notice]
    assert_equal "new_handle", @subscriber.identity.reload.handle
  end

  test "html update falls back to root without a referer" do
    sign_in_subscriber(@subscriber)

    patch "/handle", params: { handle: "fresh_handle" }

    assert_redirected_to "/"
  end

  test "html update with an invalid handle keeps the old one" do
    sign_in_subscriber(@subscriber)

    patch "/handle", params: { handle: "ab" }

    assert_redirected_to "/"
    assert_equal "Handle could not be updated.", flash[:alert]
    assert_equal "subscriber1", @subscriber.identity.reload.handle
  end

  test "html update rejects a handle taken by another identity, case-insensitively" do
    sign_in_subscriber(@subscriber)

    patch "/handle", params: { handle: "ADMIN_USER" }

    assert_equal "Handle could not be updated.", flash[:alert]
    assert_equal "subscriber1", @subscriber.identity.reload.handle
  end

  test "turbo stream update replaces the form with the new handle" do
    sign_in_subscriber(@subscriber)

    patch "/handle", params: { handle: "streamed" }, as: :turbo_stream

    assert_response :success
    assert_equal "text/vnd.turbo-stream.html", response.media_type
    assert_includes response.body, %(<turbo-stream action="replace" target="handle_form">)
    assert_includes response.body, "@streamed"
    assert_equal "streamed", @subscriber.identity.reload.handle
  end

  test "turbo stream update with an invalid handle re-renders the form" do
    sign_in_subscriber(@subscriber)

    patch "/handle", params: { handle: "bad handle!" }, as: :turbo_stream

    assert_response :success
    assert_includes response.body, %(<turbo-stream action="replace" target="handle_form">)
    assert_includes response.body, %(action="/handle")
    assert_equal "subscriber1", @subscriber.identity.reload.handle
  end
end
