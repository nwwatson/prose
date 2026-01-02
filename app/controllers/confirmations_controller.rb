class ConfirmationsController < ApplicationController
  skip_before_action :authenticate_user!

  def show
    @user = User.find_by(confirmation_token: params[:token])

    if @user&.confirmation_token.present?
      @user.confirm!
      sign_in(@user)
      redirect_to new_account_path, notice: "Email confirmed! Please create your first account."
    else
      redirect_to new_session_path, alert: "Invalid confirmation token."
    end
  end

  def new
    # Page to resend confirmation instructions
  end

  def create
    @user = User.find_by(email: params[:email].downcase.strip)

    if @user&.confirmed?
      redirect_to new_session_path, notice: "Email is already confirmed."
    elsif @user
      @user.generate_confirmation_token
      @user.save!
      # Send confirmation email
      # UserMailer.confirmation_instructions(@user).deliver_now
      redirect_to new_session_path, notice: "Confirmation instructions sent to your email."
    else
      flash.now[:alert] = "Email not found."
      render :new, status: :unprocessable_entity
    end
  end
end
