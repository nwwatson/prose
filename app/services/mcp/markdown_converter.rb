module Mcp
  class MarkdownConverter
    def self.to_html(markdown)
      MarkdownRenderer.to_html(markdown, trusted: true)
    end
  end
end
