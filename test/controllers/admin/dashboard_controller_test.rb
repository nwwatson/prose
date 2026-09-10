require "test_helper"

class Admin::DashboardControllerTest < ActionDispatch::IntegrationTest
  test "GET show requires authentication" do
    get admin_root_path
    assert_redirected_to new_admin_session_path
  end

  test "does not run configure_ruby_llm! before non-AI admin actions" do
    before_action_names = Admin::DashboardController._process_action_callbacks
      .select { |callback| callback.kind == :before }
      .map(&:filter)

    assert_not_includes before_action_names, :configure_ruby_llm!
  end

  test "GET show renders for signed in user" do
    sign_in_as(:admin)
    get admin_root_path
    assert_response :success
    assert_select "h1", text: "Dashboard"
  end

  test "GET show renders for writer" do
    sign_in_as(:writer)
    get admin_root_path
    assert_response :success
  end

  test "GET show displays newsletter stats" do
    sign_in_as(:admin)
    get admin_root_path
    assert_response :success
    assert_select "div", text: /Newsletters Sent/
  end

  test "GET show displays published posts count" do
    sign_in_as(:admin)
    get admin_root_path
    assert_response :success
    assert_select "div", text: Post.published.count.to_s
  end

  test "GET show displays traffic sources panel" do
    sign_in_as(:admin)
    get admin_root_path
    assert_response :success
    assert_select "h2", text: "Traffic Sources"
  end

  test "GET show displays top engaged posts" do
    sign_in_as(:admin)
    get admin_root_path
    assert_response :success
    assert_select "h2", text: "Top Engaged Posts"
  end

  test "GET show displays subscriber acquisition" do
    sign_in_as(:admin)
    get admin_root_path
    assert_response :success
    assert_select "h2", text: "Subscriber Acquisition"
  end
end
