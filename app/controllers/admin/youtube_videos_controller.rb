module Admin
  class YouTubeVideosController < BaseController
    def create
      youtube_video = YouTubeVideo.find_or_create_from_url(params[:url])

      if youtube_video&.persisted?
        render json: {
          sgid: youtube_video.attachable_sgid,
          html: render_to_string(partial: "youtube_videos/youtube_video", locals: { youtube_video: youtube_video }, layout: false)
        }
      else
        render json: { error: "Could not process YouTube URL" }, status: :unprocessable_entity
      end
    end
  end
end
