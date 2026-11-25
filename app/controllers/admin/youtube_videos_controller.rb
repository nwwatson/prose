module Admin
  class YouTubeVideosController < BaseController
    include Admin::OembedEmbeddable

    private

    def embed_class
      YouTubeVideo
    end

    def embed_error_message
      "Could not process YouTube URL"
    end
  end
end
