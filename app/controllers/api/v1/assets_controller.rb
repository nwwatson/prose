module Api
  module V1
    class AssetsController < Api::V1::BaseController
      def create
        blob = if params[:file].present?
          ActiveStorage::Blob.create_and_upload!(io: params[:file].to_io, filename: params[:file].original_filename, content_type: params[:file].content_type)
        elsif params[:data].present? && params[:filename].present?
          io = StringIO.new(Base64.decode64(params[:data]))
          content_type = params[:content_type].presence || Marcel::MimeType.for(name: params[:filename])
          ActiveStorage::Blob.create_and_upload!(io: io, filename: params[:filename], content_type: content_type)
        end

        return render json: { error: "Provide either a multipart 'file' or 'filename'/'data' (base64)" }, status: :unprocessable_entity unless blob

        url = Rails.application.routes.url_helpers.rails_blob_path(blob, only_path: true)
        render json: { url: url, filename: blob.filename.to_s, content_type: blob.content_type, byte_size: blob.byte_size }, status: :created
      end
    end
  end
end
