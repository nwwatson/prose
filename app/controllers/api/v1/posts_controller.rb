module Api
  module V1
    class PostsController < Api::V1::BaseController
      def index
        posts = Post.for_listing.includes(:tags)
        posts = posts.where(status: params[:status]) if params[:status].present?

        if params[:category].present?
          category = Category.find_by(name: params[:category]) || Category.find_by(slug: params[:category])
          posts = posts.where(category: category)
        end

        if params[:tag].present?
          tag = Tag.find_by(name: params[:tag]) || Tag.find_by(slug: params[:tag])
          posts = posts.joins(:tags).where(tags: { id: tag&.id })
        end

        posts = posts.search(params[:search]) if params[:search].present?
        posts = paginate(posts.order(created_at: :desc))

        render json: { posts: posts.map { |post| Mcp::PostSerializer.call(post) } }
      end

      def show
        render json: Mcp::PostSerializer.call(find_post, include_content: true)
      end

      def create
        post = Post.new(post_params.except(:content, :tags, :category))
        post.user = Current.user
        post.status = :draft
        post.content = Mcp::MarkdownConverter.to_html(post_params[:content]) if post_params[:content].present?
        post.category = find_category(post_params[:category]) if post_params[:category].present?
        post.save!
        post.tags = find_or_create_tags(post_params[:tags]) if post_params[:tags].present?

        render json: Mcp::PostSerializer.call(post.reload, include_content: true), status: :created
      end

      def update
        post = find_post
        attrs = post_params.except(:content, :tags, :category).to_h
        attrs[:category] = find_category(post_params[:category]) if post_params.key?(:category)
        post.update!(attrs) if attrs.any?
        post.content = Mcp::MarkdownConverter.to_html(post_params[:content]) if post_params.key?(:content)
        post.tags = find_or_create_tags(post_params[:tags]) if post_params.key?(:tags)
        post.save! if post.changed?

        render json: Mcp::PostSerializer.call(post.reload, include_content: true)
      end

      def destroy
        find_post.destroy!
        head :no_content
      end

      def publish
        post = find_post
        post.publish!
        render json: Mcp::PostSerializer.call(post.reload)
      end

      def schedule
        post = find_post
        time = Time.iso8601(params.require(:published_at))
        post.schedule!(time)
        render json: Mcp::PostSerializer.call(post.reload)
      rescue ArgumentError
        render json: { error: "Invalid datetime for published_at" }, status: :unprocessable_entity
      end

      def unpublish
        post = find_post
        post.revert_to_draft!
        render json: Mcp::PostSerializer.call(post.reload)
      end

      private

      def find_post
        identifier = params[:slug]
        identifier.match?(/\A\d+\z/) ? Post.find(identifier) : Post.find_by!(slug: identifier)
      end

      def find_category(name_or_slug)
        Category.find_by(name: name_or_slug) || Category.find_by(slug: name_or_slug)
      end

      def find_or_create_tags(names)
        names.map { |name| Tag.find_or_create_by!(name: name.strip) }
      end

      def post_params
        params.permit(:title, :subtitle, :slug, :category, :meta_description, :featured, :content, tags: [])
      end
    end
  end
end
