module Admin
  module PostScoped
    extend ActiveSupport::Concern

    included do
      before_action :set_post
    end

    private

    def set_post
      @post = Post.find_by!(slug: params[:post_id])
    end
  end
end
