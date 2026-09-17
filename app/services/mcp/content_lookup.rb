module Mcp
  # Post/category/tag/upload lookups shared by the MCP tools (`Mcp::Tools::Base`)
  # and the REST API controllers (`Api::V1::PostsController`, `Api::V1::AssetsController`).
  module ContentLookup
    private

    def find_post(identifier)
      identifier = identifier.to_s
      identifier.match?(/\A\d+\z/) ? Post.find(identifier) : Post.find_by!(slug: identifier)
    end

    def find_category(name_or_slug)
      Category.find_by(name: name_or_slug) || Category.find_by(slug: name_or_slug)
    end

    def find_tag(name_or_slug)
      Tag.find_by(name: name_or_slug) || Tag.find_by(slug: name_or_slug)
    end

    def find_or_create_tags(names)
      Array(names).map { |name| name.to_s.strip }.reject(&:blank?).map { |name| Tag.find_or_create_by!(name: name) }
    end

    def decode_upload(data:, filename:, content_type: nil)
      io = StringIO.new(Base64.decode64(data))
      resolved_content_type = content_type.presence || Marcel::MimeType.for(name: filename)
      [ io, resolved_content_type ]
    end
  end
end
