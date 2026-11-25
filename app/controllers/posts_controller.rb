class PostsController < ApplicationController
  include Trackable
  include Paginatable

  def index
    @query = params[:q]&.strip.presence
    @featured_posts = Post.live.featured.by_publication_date.for_listing.limit(1)
    all_posts = Post.live.where.not(id: @featured_posts.select(:id)).by_publication_date.for_listing
    all_posts = all_posts.search(@query) if @query

    @posts = paginate(all_posts)

    @snippets = @query ? viewable_snippets(@posts, @query) : {}

    if turbo_frame_request_id&.start_with?("posts_page_")
      render partial: "posts/post_page", locals: { posts: @posts, page: @page, next_page: @next_page, query: @query }, layout: false
    end
  end

  def show
    @post = Post.live.includes(:user, :category, :tags).find_by!(slug: params[:slug])
    @can_view = can_view_post?(@post)
    @related_posts = @post.related_posts
    @previous_post = @post.previous_post
    @next_post = @post.next_post
    @comments = @post.threaded_comments
    track_post_view(@post)
  end

  private

  # Body snippets quote the post's text, so gated posts only get one for readers
  # who may read them. Without a snippet the card (and its cache key) matches the
  # plain listing.
  def viewable_snippets(posts, query)
    Post.search_with_snippets(query).slice(*posts.select { |post| can_view_post?(post) }.map(&:id))
  end
end
