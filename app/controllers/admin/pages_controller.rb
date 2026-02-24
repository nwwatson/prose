module Admin
  class PagesController < BaseController
    layout :choose_layout

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
        respond_to do |format|
          format.html { redirect_to edit_admin_page_path(@page), notice: t("flash.admin.pages.created") }
          format.json { render json: page_json(@page), status: :created }
        end
      else
        respond_to do |format|
          format.html { render :new, status: :unprocessable_entity }
          format.json { render json: { errors: @page.errors.full_messages }, status: :unprocessable_entity }
        end
      end
    end

    def edit
    end

    def update
      if @page.update(page_params)
        respond_to do |format|
          format.html { redirect_to edit_admin_page_path(@page), notice: t("flash.admin.pages.updated") }
          format.json { render json: page_json(@page), status: :ok }
        end
      else
        respond_to do |format|
          format.html { render :edit, status: :unprocessable_entity }
          format.json { render json: { errors: @page.errors.full_messages }, status: :unprocessable_entity }
        end
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

    def page_json(page)
      {
        slug: page.to_param,
        url: admin_page_path(page),
        edit_url: edit_admin_page_path(page)
      }
    end

    def choose_layout
      action_name.in?(%w[new edit create update]) ? "admin_page_editor" : "admin"
    end
  end
end
