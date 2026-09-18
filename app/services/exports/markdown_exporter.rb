module Exports
  # Builds a zip archive of every post and page as a Markdown file with YAML
  # front matter. Featured images and inline image attachments are bundled
  # under images/ and referenced by relative path, so the archive is portable
  # to static site generators without the original site running.
  #
  #   posts/<slug>.md
  #   pages/<slug>.md
  #   images/<blob id>-<filename>
  class MarkdownExporter
    include ActionView::Helpers::TagHelper

    IMAGES_DIR = "images".freeze

    def self.call
      new.call
    end

    # Returns a rewound Tempfile containing the zip archive. The caller owns
    # the file and should close! it once it has been attached.
    def call
      @blobs = {}
      tempfile = Tempfile.new([ "prose-markdown-export", ".zip" ], binmode: true)

      Zip::OutputStream.open(tempfile.path) do |zip|
        posts.find_each { |post| write_entry(zip, "posts/#{post.slug}.md", post_document(post)) }
        pages.find_each { |page| write_entry(zip, "pages/#{page.slug}.md", page_document(page)) }
        @blobs.each { |path, blob| write_blob(zip, path, blob) }
      end

      tempfile.rewind
      tempfile
    end

    private

    def posts
      Post.includes(:category, :tags, :rich_text_content, featured_image_attachment: :blob, user: :identity)
    end

    def pages
      Page.includes(:rich_text_content, user: :identity)
    end

    def post_document(post)
      front_matter = {
        "title" => post.title,
        "subtitle" => post.subtitle,
        "slug" => post.slug,
        "status" => post.status,
        "visibility" => post.visibility,
        "published_at" => post.published_at&.iso8601,
        "author" => post.user&.display_name,
        "category" => post.category&.name,
        "tags" => post.tags.map(&:name).sort,
        "featured" => post.featured,
        "meta_description" => post.meta_description,
        "featured_image" => post.featured_image.attached? ? "../#{register_blob(post.featured_image.blob)}" : nil
      }

      document(front_matter, post.content)
    end

    def page_document(page)
      front_matter = {
        "title" => page.title,
        "slug" => page.slug,
        "status" => page.status,
        "published_at" => page.published_at&.iso8601,
        "author" => page.user&.display_name,
        "meta_description" => page.meta_description
      }

      document(front_matter, page.content)
    end

    def document(front_matter, rich_text)
      front_matter = front_matter.reject { |_key, value| value.nil? || value == [] }
      "#{front_matter.to_yaml}---\n\n#{markdown_for(rich_text)}"
    end

    def markdown_for(rich_text)
      return "" if rich_text.blank? || rich_text.body.blank?

      html = rich_text.body.render_attachments { |attachment| attachment_html(attachment) }.to_html
      ReverseMarkdown.convert(html, unknown_tags: :bypass, github_flavored: true).strip + "\n"
    end

    # Markdown files live one directory below the archive root, hence "../".
    def attachment_html(attachment)
      attachable = attachment.attachable

      case attachable
      when ActiveStorage::Blob
        if attachable.image?
          tag.p(tag.img(src: "../#{register_blob(attachable)}", alt: attachment.caption.presence || attachable.filename.to_s))
        else
          tag.p(tag.a(attachable.filename.to_s, href: "../#{register_blob(attachable)}"))
        end
      when XPost, YoutubeVideo
        tag.p(tag.a(attachable.url, href: attachable.url))
      else
        text = attachment.to_plain_text
        text.present? ? tag.p(text) : ""
      end
    end

    # Filenames are slugified: a space in a Markdown link target breaks the link.
    def register_blob(blob)
      base = blob.filename.base.parameterize.presence || "file"
      extension = blob.filename.extension_with_delimiter.downcase
      path = "#{IMAGES_DIR}/#{blob.id}-#{base}#{extension}"
      @blobs[path] ||= blob
      path
    end

    def write_entry(zip, path, content)
      zip.put_next_entry(path)
      zip.write(content)
    end

    # Streams the blob in chunks so large images never sit fully in memory.
    def write_blob(zip, path, blob)
      zip.put_next_entry(path)
      blob.download { |chunk| zip.write(chunk) }
    rescue ActiveStorage::FileNotFoundError
      Rails.logger.warn("[Exports::MarkdownExporter] Skipping missing file for blob #{blob.id}")
    end
  end
end
