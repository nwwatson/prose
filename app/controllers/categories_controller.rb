class CategoriesController < ApplicationController
  def show
    @category = Category.find_by!(slug: params[:slug])
    @posts = @category.posts.live.by_publication_date.includes(:user)
  end
end
