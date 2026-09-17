module Api
  module V1
    class PostsController < Api::V1::BaseController
      class UnknownCategory < StandardError; end

      rescue_from UnknownCategory, with: ->(exception) { render_error(exception.message) }

      def index
        posts = Post.for_listing.includes(:tags)
        posts = posts.where(status: params[:status]) if params[:status].present?

        if params[:category].present?
          category = find_category(params[:category])
          posts = category ? posts.where(category: category) : posts.none
        end

        if params[:tag].present?
          tag = find_tag(params[:tag])
          posts = tag ? posts.where(id: tag.posts.select(:id)) : posts.none
        end

        posts = posts.search(params[:search]) if params[:search].present?
        posts = paginate(posts.order(created_at: :desc))

        render json: { posts: posts.map { |post| Mcp::PostSerializer.call(post) } }
      end

      def show
        render json: Mcp::PostSerializer.call(find_post(params[:slug]), include_content: true)
      end

      def create
        post = Post.new(post_params.except(:content, :tags, :category))
        post.user = Current.user
        post.status = :draft
        post.content = Mcp::MarkdownConverter.to_html(post_params[:content]) if post_params[:content].present?
        post.category = resolve_category(post_params[:category]) if post_params[:category].present?
        post.save!
        post.tags = find_or_create_tags(post_params[:tags]) if post_params[:tags].present?

        render json: Mcp::PostSerializer.call(post.reload, include_content: true), status: :created
      end

      def update
        post = find_post(params[:slug])
        attrs = post_params.except(:content, :tags, :category).to_h
        attrs[:category] = resolve_category(post_params[:category]) if post_params.key?(:category)
        post.assign_attributes(attrs)
        post.content = Mcp::MarkdownConverter.to_html(post_params[:content].to_s) if post_params.key?(:content)
        # Always save: a content-only change lives on the ActionText record, so
        # `post.changed?` stays false and a guarded save would silently drop it.
        post.save!
        post.tags = find_or_create_tags(post_params[:tags]) if post_params.key?(:tags)

        render json: Mcp::PostSerializer.call(post.reload, include_content: true)
      end

      def destroy
        find_post(params[:slug]).destroy!
        head :no_content
      end

      def publish
        post = find_post(params[:slug])
        post.publish!
        render json: Mcp::PostSerializer.call(post.reload)
      end

      def schedule
        post = find_post(params[:slug])
        time = Time.iso8601(params.require(:published_at))
        post.schedule!(time)
        render json: Mcp::PostSerializer.call(post.reload)
      rescue ArgumentError
        render json: { error: "Invalid datetime for published_at" }, status: :unprocessable_entity
      end

      def unpublish
        post = find_post(params[:slug])
        post.revert_to_draft!
        render json: Mcp::PostSerializer.call(post.reload)
      end

      private

      # A blank value clears the category; an unknown name/slug is a client error
      # rather than silently leaving the post uncategorized.
      def resolve_category(name_or_slug)
        return nil if name_or_slug.blank?

        find_category(name_or_slug) || raise(UnknownCategory, "Category not found: #{name_or_slug}")
      end

      def post_params
        params.permit(:title, :subtitle, :slug, :category, :meta_description, :featured, :content, tags: [])
      end
    end
  end
end
