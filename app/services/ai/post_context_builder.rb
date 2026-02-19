module Ai
  class PostContextBuilder
    MAX_CONTENT_LENGTH = 50_000

    def initialize(post)
      @post = post
    end

    def build
      build_with_overrides
    end

    def build_with_overrides(title: nil, subtitle: nil, content: nil)
      sections = []
      sections << "Title: #{title || @post.title}"
      sections << "Subtitle: #{subtitle || @post.subtitle}" if (subtitle || @post.subtitle).present?
      sections << "Category: #{@post.category.name}" if @post.category.present?
      sections << "Tags: #{@post.tags.pluck(:name).join(', ')}" if @post.tags.any?
      sections << "Status: #{@post.status}"
      sections << ""
      sections << "Content:"
      sections << truncate_content(content || plain_text_content)

      sections.join("\n")
    end

    private

    def plain_text_content
      body = @post.content&.body
      return "" if body.blank?

      html_to_plain_text(body.to_s)
    end

    # Convert HTML to plain text while preserving line breaks between
    # block-level elements (headings, paragraphs, list items, etc.)
    def html_to_plain_text(html)
      doc = Nokogiri::HTML.fragment(html)
      extract_text(doc).gsub(/\n{3,}/, "\n\n").strip
    end

    def extract_text(node)
      return node.text if node.text?
      return "" if node.comment?

      children_text = node.children.map { |child| extract_text(child) }.join
      block_element?(node) ? "\n#{children_text}\n" : children_text
    end

    def block_element?(node)
      %w[p div h1 h2 h3 h4 h5 h6 blockquote ul ol li br hr figure pre].include?(node.name)
    end

    def truncate_content(text)
      text.to_s.truncate(MAX_CONTENT_LENGTH)
    end
  end
end
