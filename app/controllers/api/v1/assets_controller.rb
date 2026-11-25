module Api
  module V1
    class AssetsController < Api::V1::BaseController
      def create
        asset = if params[:file].is_a?(ActionDispatch::Http::UploadedFile)
          Mcp::AssetUploader.call(io: params[:file].to_io, filename: params[:file].original_filename, content_type: params[:file].content_type)
        elsif params[:data].present? && params[:filename].present?
          io, content_type = decode_upload(data: params[:data], filename: params[:filename], content_type: params[:content_type])
          Mcp::AssetUploader.call(io: io, filename: params[:filename], content_type: content_type)
        end

        return render_error("Provide either a multipart 'file' or 'filename'/'data' (base64)") unless asset

        render json: asset, status: :created
      end
    end
  end
end
