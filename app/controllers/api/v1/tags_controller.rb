module Api
  module V1
    class TagsController < Api::V1::BaseController
      def index
        post_counts = Tag.post_counts
        tags = Tag.all.order(:name).map do |tag|
          { id: tag.id, name: tag.name, slug: tag.slug, post_count: post_counts.fetch(tag.id, 0) }
        end

        render json: { tags: tags }
      end

      def create
        tag = Tag.find_or_create_by!(name: tag_params[:name].to_s.strip)

        render json: { id: tag.id, name: tag.name, slug: tag.slug }, status: :created
      end

      private

      def tag_params
        params.permit(:name)
      end
    end
  end
end
