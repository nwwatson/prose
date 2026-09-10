class TagsController < ApplicationController
  def show
    @tag = Tag.find_by!(slug: params[:slug])
    @posts = @tag.posts.live.by_publication_date.for_listing
  end
end
