module Admin
  class PostsController < BaseController
    layout :choose_layout

    before_action :set_post, only: [ :edit, :update, :destroy ]

    def index
      @posts = Post.includes(:user, :category)

      case params[:status]
      when "published"
        @posts = @posts.published
      when "scheduled"
        @posts = @posts.scheduled
      when "draft"
        @posts = @posts.draft
      end

      if params[:search].present?
        @posts = @posts.where("title LIKE ?", "%#{Post.sanitize_sql_like(params[:search])}%")
      end

      @posts = @posts.order(updated_at: :desc)
    end

    def new
      @post = current_user.posts.build(status: :draft)
    end

    def create
      @post = current_user.posts.build(post_params)

      if @post.save
        redirect_to edit_admin_post_path(@post), notice: "Post created."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      if @post.update(post_params)
        redirect_to edit_admin_post_path(@post), notice: "Post updated."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @post.destroy
      redirect_to admin_posts_path, notice: "Post deleted."
    end

    private

    def set_post
      @post = Post.find_by!(slug: params[:id])
    end

    def post_params
      params.require(:post).permit(:title, :subtitle, :slug, :status, :published_at, :scheduled_at, :featured, :category_id, :content, :meta_description, :featured_image, tag_ids: [])
    end

    def choose_layout
      action_name.in?(%w[new edit create update]) ? "admin_editor" : "admin"
    end
  end
end
