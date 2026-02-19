module Admin
  module Ai
    class BaseController < Admin::BaseController
      include ::Ai::Configurable

      before_action :require_ai_configured
      before_action :set_post

      private

      def set_post
        @post = Post.find_by!(slug: params[:post_id])
      end
    end
  end
end
