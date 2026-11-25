module Api
  module V1
    class SiteController < Api::V1::BaseController
      def show
        render json: Mcp::SiteInfo.call
      end
    end
  end
end
