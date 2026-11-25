class ReadingListController < ApplicationController
  include Paginatable

  def show
    # Anonymous readers' lists live in localStorage; the page fetches their
    # posts from ReadingListPostsController once the bookmark JS has the ids.
    return unless identity_signed_in?

    @posts = paginate(current_identity.reading_list_posts)

    render layout: false if post_page_frame_request?
  end
end
