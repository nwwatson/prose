module Admin
  class SessionsController < ApplicationController
    include Authentication

    layout "admin_auth"

    before_action :redirect_to_setup, only: [ :new, :create ]
    before_action :redirect_if_signed_in, only: [ :new, :create ]

    def new
    end

    def create
      user = User.authenticate_by_email_and_password(params[:email], params[:password])

      if user
        start_session(user, ip_address: request.remote_ip, user_agent: request.user_agent)
        redirect_to admin_root_path, notice: t("flash.admin.sessions.signed_in")
      else
        flash.now[:alert] = "Invalid email or password."
        render :new, status: :unprocessable_entity
      end
    end

    def destroy
      resume_session
      end_session
      redirect_to new_admin_session_path, notice: t("flash.admin.sessions.signed_out")
    end

    private

    def redirect_to_setup
      redirect_to new_admin_setup_path if User.none?
    end

    def redirect_if_signed_in
      redirect_to admin_root_path if resume_session
    end
  end
end
