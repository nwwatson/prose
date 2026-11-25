class SitemapsController < ApplicationController
  # The builder only reads slugs and post/page timestamps, so skip the rest of
  # each row (a post's body_plain in particular).
  def index
    @posts = Post.live.by_publication_date.select(:slug, :updated_at)
    @pages = Page.live.select(:slug, :updated_at)
    @categories = Category.select(:slug)
    @tags = Tag.select(:slug)

    respond_to do |format|
      format.xml
    end
  end
end
