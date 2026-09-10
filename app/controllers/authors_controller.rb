class AuthorsController < ApplicationController
  include Paginatable

  def index
    @authors = Identity.authors.with_handle.includes(:user, avatar_attachment: :blob).order(:name)
    @post_counts = Post.live.group(:user_id).count
  end

  def show
    @identity = Identity.authors.with_handle.find_by!(handle: params[:handle])
    all_posts = @identity.user.posts.live.by_publication_date.includes(:category)

    @posts = paginate(all_posts)
    @total_posts = all_posts.count
  end
end
