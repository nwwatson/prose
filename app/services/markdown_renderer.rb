class MarkdownRenderer
  def self.to_html(markdown)
    return "" if markdown.blank?

    Commonmarker.to_html(
      markdown,
      options: {
        render: { unsafe: false, hardbreaks: true },
        extension: { autolink: true, strikethrough: true }
      },
      plugins: { syntax_highlighter: nil }
    )
  end
end
