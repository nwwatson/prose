module Admin
  class PostsController < BaseController
    layout :choose_layout

    before_action :set_post, only: [ :edit, :update, :destroy, :preview ]

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

      @posts = @posts.search(params[:search]) if params[:search].present?

      @posts = @posts.order(updated_at: :desc)
    end

    def new
      @post = current_user.posts.build(status: :draft)
    end

    def create
      @post = current_user.posts.build(post_params)

      if @post.save
        respond_to do |format|
          format.html { redirect_to edit_admin_post_path(@post), notice: t("flash.admin.posts.created") }
          format.json { render json: post_json(@post), status: :created }
        end
      else
        respond_to do |format|
          format.html { render :new, status: :unprocessable_entity }
          format.json { render json: { errors: @post.errors.full_messages }, status: :unprocessable_entity }
        end
      end
    end

    def edit
    end

    def update
      if @post.update(post_params)
        respond_to do |format|
          format.html { redirect_to edit_admin_post_path(@post), notice: t("flash.admin.posts.updated") }
          format.json { render json: post_json(@post), status: :ok }
        end
      else
        respond_to do |format|
          format.html { render :edit, status: :unprocessable_entity }
          format.json { render json: { errors: @post.errors.full_messages }, status: :unprocessable_entity }
        end
      end
    end

    def preview
      @post = Post.includes(:user, :category, :tags).find_by!(slug: params[:id])
      render partial: "preview", locals: { post: @post }, layout: false
    end

    def destroy
      @post.destroy
      redirect_to admin_posts_path, notice: t("flash.admin.posts.deleted")
    end

    private

    def set_post
      @post = Post.find_by!(slug: params[:id])
    end

    def post_params
      params.require(:post).permit(:title, :subtitle, :slug, :status, :published_at, :scheduled_at, :featured, :category_id, :content, :meta_description, :featured_image, tag_ids: [])
    end

    def post_json(post)
      {
        slug: post.to_param,
        url: admin_post_path(post),
        edit_url: edit_admin_post_path(post)
      }
    end

    def choose_layout
      action_name.in?(%w[new edit create update]) ? "admin_editor" : "admin"
    end
  end
end
