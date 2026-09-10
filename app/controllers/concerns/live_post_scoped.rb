module LivePostScoped
  extend ActiveSupport::Concern

  included do
    before_action :set_post
  end

  private

  def set_post
    @post = Post.live.find_by!(slug: params[:post_slug])
  end
end
