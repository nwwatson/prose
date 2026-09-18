class ReadingListController < ApplicationController
  def show
    # Anonymous readers' lists live in localStorage; the page fetches their
    # posts from ReadingListPostsController once the bookmark JS has the ids.
    @posts = current_identity.reading_list_posts if identity_signed_in?
  end
end
