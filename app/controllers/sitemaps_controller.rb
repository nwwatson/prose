class SitemapsController < ApplicationController
  def index
    @posts = Post.live.by_publication_date
    @pages = Page.live
    @categories = Category.all
    @tags = Tag.all

    respond_to do |format|
      format.xml
    end
  end
end
