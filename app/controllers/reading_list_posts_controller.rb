# Renders post cards for an anonymous reader's localStorage reading list, into
# the reading list page's turbo frame. Ids are passed newest-first.
class ReadingListPostsController < ApplicationController
  def index
    ids = params[:ids].to_s.split(",").map(&:to_i).select(&:positive?).uniq.first(ReadingListItem::MAX_ITEMS)
    posts = Post.live.for_listing.where(id: ids).index_by(&:id)

    render partial: "reading_list/posts", locals: { posts: ids.filter_map { |id| posts[id] }, framed: true }
  end
end
