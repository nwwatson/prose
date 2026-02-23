require "test_helper"

class Admin::SetupControllerTest < ActionDispatch::IntegrationTest
  test "GET new renders setup form when no users exist" do
    destroy_all_users

    get new_admin_setup_path
    assert_response :success
    assert_select "form"
    assert_select "input[name='user[display_name]']"
    assert_select "input[name='user[email]']"
    assert_select "input[name='user[password]']"
  end

  test "GET new redirects to admin root when users exist" do
    get new_admin_setup_path
    assert_redirected_to admin_root_path
  end

  test "POST create creates admin user and signs in" do
    destroy_all_users

    assert_difference "User.count", 1 do
      post admin_setup_path, params: {
        user: {
          display_name: "First Admin",
          email: "admin@newsite.com",
          password: "P@ssw0rd!Strong1",
          password_confirmation: "P@ssw0rd!Strong1"
        }
      }
    end

    user = User.last
    assert user.admin?
    assert_equal "First Admin", user.display_name
    assert_redirected_to admin_root_path
  end

  test "POST create renders errors for invalid input" do
    destroy_all_users

    assert_no_difference "User.count" do
      post admin_setup_path, params: {
        user: {
          display_name: "",
          email: "bad",
          password: "short",
          password_confirmation: "short"
        }
      }
    end

    assert_response :unprocessable_entity
  end

  test "POST create redirects when users already exist" do
    assert_no_difference "User.count" do
      post admin_setup_path, params: {
        user: {
          display_name: "Sneaky",
          email: "sneaky@example.com",
          password: "P@ssw0rd!Strong1",
          password_confirmation: "P@ssw0rd!Strong1"
        }
      }
    end

    assert_redirected_to admin_root_path
  end

  test "admin routes redirect to setup when no users exist" do
    destroy_all_users

    get admin_root_path
    assert_redirected_to new_admin_setup_path
  end

  test "admin session login redirects to setup when no users exist" do
    destroy_all_users

    get new_admin_session_path
    assert_redirected_to new_admin_setup_path
  end

  private

  def destroy_all_users
    Comment.delete_all
    Love.delete_all
    Subscriber.update_all(source_post_id: nil)
    PostView.delete_all
    PostTag.delete_all
    Chat.delete_all
    Post.delete_all
    Session.delete_all
    ApiToken.delete_all
    NewsletterDelivery.delete_all
    Newsletter.delete_all
    User.delete_all
  end
end
