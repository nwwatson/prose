module Api
  module V1
    class CategoriesController < Api::V1::BaseController
      def index
        post_counts = Category.post_counts
        categories = Category.ordered.map do |category|
          { id: category.id, name: category.name, slug: category.slug, description: category.description,
            position: category.position, post_count: post_counts.fetch(category.id, 0) }
        end

        render json: { categories: categories }
      end
    end
  end
end
