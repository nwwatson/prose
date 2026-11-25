module Api
  module V1
    class TagsController < Api::V1::BaseController
      def index
        render json: { tags: Mcp::TagSerializer.all }
      end

      def create
        tag = Tag.find_or_create_by!(name: tag_params[:name].to_s.strip)

        render json: Mcp::TagSerializer.call(tag), status: :created
      end

      private

      def tag_params
        params.permit(:name)
      end
    end
  end
end
