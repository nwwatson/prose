class TagsController < ApplicationController
  include Paginatable

  def show
    @tag = Tag.find_by!(slug: params[:slug])
    @posts = paginate(@tag.posts.live.by_publication_date.for_listing)

    render layout: false if post_page_frame_request?
  end
end
