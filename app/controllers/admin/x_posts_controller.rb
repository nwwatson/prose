module Admin
  class XPostsController < BaseController
    include Admin::OembedEmbeddable

    private

    def embed_class
      XPost
    end

    def embed_error_message
      "Could not process X post URL"
    end
  end
end
