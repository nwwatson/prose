module ActivityPub
  # Serves a post as an ActivityPub Article when a fediverse server asks for
  # /posts/:slug with an ActivityPub Accept header (see ActivityPub::Negotiation).
  class ObjectsController < BaseController
    def show
      post = Post.live.find_by!(slug: params[:slug])
      render_activity ArticleSerializer.call(post)
    rescue ActiveRecord::RecordNotFound
      head :not_found
    end
  end
end
