class SessionsController < ApplicationController
  skip_before_action :authenticate_user!, only: [ :new, :create ]

  def new
    redirect_to root_path if user_signed_in?
  end

  def create
    user = User.find_by(email: params[:email].downcase.strip)

    if user&.account_locked?
      flash.now[:alert] = "Account is locked due to too many failed sign in attempts."
      render :new, status: :unprocessable_entity
      return
    end

    if user&.authenticate(params[:password])
      if user.confirmed?
        sign_in(user, remember_me: params[:remember_me] == "1")
        redirect_to root_path, notice: "Successfully signed in!"
      else
        flash.now[:alert] = "Please confirm your email address before signing in."
        render :new, status: :unprocessable_entity
      end
    else
      user&.increment_failed_attempts!
      flash.now[:alert] = "Invalid email or password."
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    sign_out
    redirect_to new_session_path, notice: "Successfully signed out!"
  end

  private

  def session_params
    params.permit(:email, :password, :remember_me)
  end
end
