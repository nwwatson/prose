class AuthorsController < ApplicationController
  PER_PAGE = 10

  def index
    @authors = Identity.authors.with_handle.includes(:user, avatar_attachment: :blob).order(:name)
  end

  def show
    @identity = Identity.authors.with_handle.find_by!(handle: params[:handle])
    all_posts = @identity.user.posts.live.by_publication_date.includes(:category)

    @page = [ params.fetch(:page, 1).to_i, 1 ].max
    offset = (@page - 1) * PER_PAGE

    @posts = all_posts.offset(offset).limit(PER_PAGE)
    @next_page = @page + 1 if all_posts.offset(offset + PER_PAGE).exists?
    @total_posts = all_posts.count
  end
end
