module Api
  module V1
    class CategoriesController < Api::V1::BaseController
      def index
        render json: { categories: Mcp::CategorySerializer.all }
      end
    end
  end
end
