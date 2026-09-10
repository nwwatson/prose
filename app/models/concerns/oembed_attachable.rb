module OembedAttachable
  extend ActiveSupport::Concern

  included do
    include ActionText::Attachable
  end

  class_methods do
    def find_or_create_from_url(url)
      normalized = normalize_url(url)
      return nil unless valid_oembed_url?(normalized)

      find_or_create_by(url: normalized) do |record|
        record.send(:assign_oembed_url_attributes)
        record.apply_oembed(OembedFetcher.fetch(record.oembed_endpoint))
      end
    end

    # Override to reject URLs that can't be resolved to a valid embed.
    def valid_oembed_url?(url)
      url.present?
    end

    def attachable_partial_path
      @attachable_partial_path ||= "#{model_name.plural}/#{model_name.singular}"
    end
  end

  def to_attachable_partial_path
    self.class.attachable_partial_path
  end
  alias_method :to_trix_content_attachment_partial_path, :to_attachable_partial_path

  private

  # Override to derive attributes from the url before the oEmbed fetch (e.g. video_id).
  def assign_oembed_url_attributes
  end
end
