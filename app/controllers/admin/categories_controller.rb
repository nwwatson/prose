module Admin
  class CategoriesController < BaseController
    include Admin::CrudResource
    crud_resource Category

    def index
      @categories = Category.ordered
      @post_counts = Category.post_counts
    end

    private

    def find_resource
      Category.find_by!(slug: params[:id])
    end

    def resource_params
      params.require(:category).permit(:name, :slug, :description, :position)
    end
  end
end
