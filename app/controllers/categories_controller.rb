class CategoriesController < ApplicationController
  def show
    @category = Category.find_by!(slug: params[:slug])
    @posts = @category.posts.live.by_publication_date.with_author
  end
end
