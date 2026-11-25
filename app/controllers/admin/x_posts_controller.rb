module Admin
  class XPostsController < BaseController
    def create
      x_post = XPost.find_or_create_from_url(params[:url].to_s)

      if x_post&.persisted?
        render json: {
          sgid: x_post.attachable_sgid,
          html: render_to_string(partial: "x_posts/x_post", formats: [ :html ], locals: { x_post: x_post }, layout: false)
        }
      else
        render json: { error: x_post&.errors&.full_messages&.join(", ") || "Could not process X post URL" }, status: :unprocessable_entity
      end
    end
  end
end
