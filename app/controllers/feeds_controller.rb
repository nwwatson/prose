class FeedsController < ApplicationController
  def index
    @posts = Post.live.by_publication_date.includes(:user, :category, :tags, :rich_text_content).limit(20)

    respond_to do |format|
      format.xml
    end
  end
end
