module Admin
  class ProfilesController < BaseController
    def edit
      @identity = current_user.identity
    end

    def update
      @identity = current_user.identity

      if @identity.update(identity_params)
        redirect_to edit_admin_profile_path, notice: "Profile updated."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    private

    def identity_params
      params.require(:identity).permit(:name, :handle, :bio, :avatar, :website_url, :twitter_handle, :github_handle)
    end
  end
end
