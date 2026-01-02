class RegistrationsController < ApplicationController
  skip_before_action :authenticate_user!

  def new
    redirect_to root_path if user_signed_in?
    @user = User.new
  end

  def create
    @user = User.new(user_params)

    if @user.save
      # Send confirmation email
      UserMailer.confirmation_instructions(@user).deliver_now

      redirect_to new_session_path,
                  notice: "Registration successful! Please check your email to confirm your account."
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def user_params
    params.require(:user).permit(:name, :email, :password, :password_confirmation)
  end
end
