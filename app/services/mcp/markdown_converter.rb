module Mcp
  class MarkdownConverter
    EXTENSIONS = %i[strikethrough table autolink tasklist].freeze

    def self.to_html(markdown)
      return "" if markdown.blank?

      Commonmarker.to_html(markdown, options: { extension: { header_ids: "" }, render: { unsafe: true } }, plugins: { syntax_highlighter: nil })
    end
  end
end
