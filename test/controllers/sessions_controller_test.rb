# frozen_string_literal: true

require "test_helper"

class SessionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
  end

  test "should get new" do
    get new_session_url
    assert_response :success
    assert_select "h2", "Sign in to Prose"
  end

  test "should redirect to accounts if already signed in" do
    sign_in_as(@user)
    get new_session_url
    assert_redirected_to root_path
  end

  test "should sign in with valid credentials" do
    post sessions_url, params: {
      email: @user.email,
      password: "password123"
    }

    assert_redirected_to root_path
    assert_equal @user.id, session[:user_id]
    follow_redirect!
    assert_select "div.notice", "Successfully signed in!"
  end

  test "should not sign in with invalid password" do
    post sessions_url, params: {
      email: @user.email,
      password: "wrongpassword"
    }

    assert_response :unprocessable_entity
    assert_nil session[:user_id]
    assert_select "div.alert", "Invalid email or password."
  end

  test "should not sign in with invalid email" do
    post sessions_url, params: {
      email: "nonexistent@example.com",
      password: "password123"
    }

    assert_response :unprocessable_entity
    assert_nil session[:user_id]
    assert_select "div.alert", "Invalid email or password."
  end

  test "should not sign in unconfirmed user" do
    unconfirmed_user = users(:two)
    post sessions_url, params: {
      email: unconfirmed_user.email,
      password: "password123"
    }

    assert_response :unprocessable_entity
    assert_nil session[:user_id]
    assert_select "div.alert", "Please confirm your email address before signing in."
  end

  test "should not sign in locked user" do
    @user.lock_account!
    post sessions_url, params: {
      email: @user.email,
      password: "password123"
    }

    assert_response :unprocessable_entity
    assert_nil session[:user_id]
    assert_select "div.alert", "Account is locked due to too many failed sign in attempts."
  end

  test "should increment failed attempts on invalid sign in" do
    initial_attempts = @user.failed_attempts
    post sessions_url, params: {
      email: @user.email,
      password: "wrongpassword"
    }

    @user.reload
    assert_equal initial_attempts + 1, @user.failed_attempts
  end

  test "should sign out" do
    sign_in_as(@user)
    delete sign_out_url

    assert_redirected_to new_session_path
    assert_nil session[:user_id]
    follow_redirect!
    assert_select "div.notice", "Successfully signed out!"
  end

  test "should handle remember me" do
    post sessions_url, params: {
      email: @user.email,
      password: "password123",
      remember_me: "1"
    }

    assert_redirected_to root_path
    @user.reload
    assert_not_nil @user.remember_token
  end

  private

  def sign_in_as(user)
    post sessions_url, params: {
      email: user.email,
      password: "password123"
    }
  end
end
