module Admin
  class SetupController < ApplicationController
    include Authentication

    layout "admin_auth"

    before_action :require_no_users

    def new
      @user = User.new
    end

    def create
      @user = User.new(user_params)
      @user.role = :admin

      if @user.save
        start_session(@user, ip_address: request.remote_ip, user_agent: request.user_agent)
        redirect_to admin_root_path, notice: t("flash.admin.setup.welcome", site_name: SiteSetting.current.site_name)
      else
        render :new, status: :unprocessable_entity
      end
    end

    private

    def user_params
      params.require(:user).permit(:email, :display_name, :password, :password_confirmation)
    end

    def require_no_users
      redirect_to admin_root_path if User.exists?
    end
  end
end
