module Admin
  # The create action for the editor's oEmbed attachments (X posts, YouTube
  # videos): finds or creates the record for params[:url] and returns what the
  # editor needs to insert it. Controllers define +embed_class+ and
  # +embed_error_message+ (used when there are no validation errors to report).
  module OembedEmbeddable
    extend ActiveSupport::Concern

    def create
      record = embed_class.find_or_create_from_url(params[:url].to_s)

      if record&.persisted?
        render json: { sgid: record.attachable_sgid, html: embed_html(record) }
      else
        error = record&.errors&.full_messages&.join(", ").presence || embed_error_message
        render json: { error: error }, status: :unprocessable_entity
      end
    end

    private

    # formats: [ :html ] because the editor asks for JSON.
    def embed_html(record)
      render_to_string(
        partial: record.to_attachable_partial_path,
        formats: [ :html ],
        locals: { record.model_name.singular.to_sym => record },
        layout: false
      )
    end
  end
end
