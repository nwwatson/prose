module Api
  module V1
    class PostsController < Api::V1::BaseController
      rescue_from Mcp::PostWriter::UnknownCategory, with: ->(exception) { render_error(exception.message) }

      def index
        result = Mcp::PostListQuery.call(params.permit(:status, :category, :tag, :search, :page, :per_page))
        set_pagination_headers(page: result.page, per_page: result.per_page, total: result.total)

        render json: { posts: result.posts.map { |post| Mcp::PostSerializer.call(post) } }
      end

      def show
        render json: Mcp::PostSerializer.call(find_post(params[:slug]), include_content: true)
      end

      def create
        post = Mcp::PostWriter.create(user: Current.user, attrs: post_params)
        render json: Mcp::PostSerializer.call(post, include_content: true), status: :created
      end

      def update
        post = Mcp::PostWriter.update(post: find_post(params[:slug]), attrs: post_params)
        render json: Mcp::PostSerializer.call(post, include_content: true)
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

      def post_params
        params.permit(:title, :subtitle, :slug, :category, :meta_description, :featured, :content, tags: [])
      end
    end
  end
end
