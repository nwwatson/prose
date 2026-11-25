module Admin
  class YouTubeVideosController < BaseController
    include Admin::OembedEmbeddable

    private

    def embed_class
      YouTubeVideo
    end

    def embed_error_message
      t("flash.admin.youtube_videos.could_not_process")
    end
  end
end
