module Admin
  class PagesController < BaseController
    include Admin::EditorResource
    uses_editor_layout "admin_page_editor"

    before_action :set_page, only: [ :edit, :update, :destroy ]

    def index
      @pages = Page.includes(:user).order(:position, :title)
    end

    def new
      @page = current_user.pages.build(status: :draft)
    end

    def create
      @page = current_user.pages.build(page_params)

      if @page.save
        respond_with_saved(@page, notice: t("flash.admin.pages.created"), status: :created)
      else
        respond_with_errors(@page, :new)
      end
    end

    def edit
    end

    def update
      if @page.update(page_params)
        respond_with_saved(@page, notice: t("flash.admin.pages.updated"), status: :ok)
      else
        respond_with_errors(@page, :edit)
      end
    end

    def destroy
      @page.destroy
      redirect_to admin_pages_path, notice: t("flash.admin.pages.deleted")
    end

    private

    def set_page
      @page = Page.find_by!(slug: params[:id])
    end

    def page_params
      params.require(:page).permit(:title, :slug, :status, :content, :meta_description, :show_in_navigation, :position, :published_at)
    end

    def resource_json(page)
      {
        slug: page.to_param,
        url: admin_page_path(page),
        edit_url: edit_admin_page_path(page)
      }
    end

    def edit_path_for(page)
      edit_admin_page_path(page)
    end
  end
end
