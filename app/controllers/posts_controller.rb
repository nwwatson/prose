class PostsController < ApplicationController
  include Trackable

  PER_PAGE = 10

  def index
    @query = params[:q]&.strip.presence
    @featured_posts = Post.live.featured.by_publication_date.limit(1)
    all_posts = Post.live.where.not(id: @featured_posts.select(:id)).by_publication_date.includes(:user, :category)
    all_posts = all_posts.search(@query) if @query

    @page = [ params.fetch(:page, 1).to_i, 1 ].max
    offset = (@page - 1) * PER_PAGE

    @posts = all_posts.offset(offset).limit(PER_PAGE)
    @next_page = @page + 1 if all_posts.offset(offset + PER_PAGE).exists?

    if turbo_frame_request_id&.start_with?("posts_page_")
      render partial: "posts/post_page", locals: { posts: @posts, page: @page, next_page: @next_page, query: @query }, layout: false
    end
  end

  def show
    @post = Post.live.includes(:user, :category, :tags).find_by!(slug: params[:slug])
    track_post_view(@post)
  end
end
