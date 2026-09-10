module Admin
  class PostsController < BaseController
    include Admin::EditorResource
    uses_editor_layout "admin_editor"

    before_action :set_post, only: [ :edit, :update, :destroy, :preview ]
    before_action :set_chat, only: [ :edit, :update ]

    def index
      @posts = Post.for_listing

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
        respond_with_saved(@post, notice: t("flash.admin.posts.created"), status: :created)
      else
        respond_with_errors(@post, :new)
      end
    end

    def edit
    end

    def update
      if @post.update(post_params)
        @post.create_version_if_needed!(user: current_user)
        respond_with_saved(@post, notice: t("flash.admin.posts.updated"), status: :ok)
      else
        respond_with_errors(@post, :edit)
      end
    end

    def preview
      render partial: "preview", locals: { post: @post }, layout: false
    end

    def destroy
      @post.destroy
      redirect_to admin_posts_path, notice: t("flash.admin.posts.deleted")
    end

    private

    def set_post
      @post = Post.includes(:user, :category, :tags).find_by!(slug: params[:id])
    end

    def set_chat
      @chat = Chat.find_or_create_for(post: @post, user: current_user, conversation_type: "chat") if SiteSetting.current.ai_configured?
    end

    def post_params
      params.require(:post).permit(:title, :subtitle, :slug, :status, :published_at, :featured, :show_toc, :category_id, :content, :meta_description, :featured_image, :visibility, tag_ids: [])
    end

    def resource_json(post)
      {
        slug: post.to_param,
        url: admin_post_path(post),
        edit_url: edit_admin_post_path(post)
      }
    end

    def edit_path_for(post)
      edit_admin_post_path(post)
    end
  end
end
