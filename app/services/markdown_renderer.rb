class MarkdownRenderer
  def self.to_html(markdown, trusted: false)
    return "" if markdown.blank?

    Commonmarker.to_html(
      markdown,
      options: {
        render: { unsafe: trusted, hardbreaks: true },
        extension: { autolink: true, strikethrough: true }
      },
      plugins: { syntax_highlighter: nil }
    )
  end
end
