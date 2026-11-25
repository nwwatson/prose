module Admin
  class XPostsController < BaseController
    include Admin::OembedEmbeddable

    private

    def embed_class
      XPost
    end

    def embed_error_message
      t("flash.admin.x_posts.could_not_process")
    end
  end
end
