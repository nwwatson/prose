module Admin
  class PostVersionsController < BaseController
    include Admin::PostScoped

    before_action :set_version, only: [ :show, :restore ]

    def index
      @versions = @post.post_versions.ordered.includes(:user)
      render layout: false
    end

    def show
      @diff = @version.diff_against_current
      render layout: false
    end

    def create
      @version = @post.create_version!(user: current_user)
      redirect_to admin_post_post_versions_path(@post), notice: t("flash.admin.post_versions.created")
    end

    def restore
      @post.restore_version!(@version)
      redirect_to edit_admin_post_path(@post), notice: t("flash.admin.post_versions.restored")
    end

    private

    def set_version
      @version = @post.post_versions.find(params[:id])
    end
  end
end
