module Admin
  class PostsController < BaseController
    include Admin::EditorResource
    uses_editor_layout "admin_editor"

    before_action :set_post, only: [ :edit, :update, :destroy, :preview ]
    before_action :load_chat, only: :edit
    before_action :load_editor_options, only: [ :new, :create, :edit, :update ]

    def index
      @posts = filter_by_status(Post.for_listing, %w[published scheduled draft])

      @posts = @posts.search(params[:search]) if params[:search].present?

      @posts = paginate(@posts.order(updated_at: :desc, id: :desc))
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
        # Only a re-rendered editor shows the chat; a JSON autosave doesn't.
        load_chat unless request.format.json?
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
      scope = action_name.in?(%w[edit preview]) ? Post.includes(:user, :category, :tags) : Post
      @post = scope.find_by!(slug: params[:id])
    end

    def load_chat
      return unless SiteSetting.current.ai_configured?

      @chat = Chat.find_or_create_for(post: @post, user: current_user, conversation_type: "chat")
      @chat_messages = @chat.conversation_messages
    end

    # Lazy relations: nothing is queried unless the editor renders.
    def load_editor_options
      @categories = Category.ordered
      @tags = Tag.order(:name)
    end

    def post_params
      params.require(:post).permit(:title, :subtitle, :slug, :status, :published_at, :featured, :show_toc, :category_id, :content, :meta_description, :featured_image, :visibility, tag_ids: [], mailing_list_ids: [])
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
