class CategoriesController < ApplicationController
  include Paginatable

  def show
    @category = Category.find_by!(slug: params[:slug])
    @posts = paginate(@category.posts.live.by_publication_date.for_listing)

    render layout: false if post_page_frame_request?
  end
end
