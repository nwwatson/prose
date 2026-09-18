module ActivityPub
  # Converts a remote Note's HTML content into the plain text/Markdown a Comment
  # body stores. Remote HTML is never stored as-is — comments are rendered
  # through MarkdownRenderer and sanitized like any locally written comment.
  module CommentBody
    module_function

    def from_html(html)
      fragment = Nokogiri::HTML5.fragment(html.to_s)
      fragment.css("script, style").each(&:remove)
      # Mastodon prefixes replies with an h-card mention of the account being
      # replied to (this site's actor), which is noise in a comment thread.
      fragment.css("span.h-card, a.mention").each do |node|
        node.remove if node.text.strip.downcase == "@#{SiteSetting.current.activitypub_username}"
      end
      fragment.css("br").each { |node| node.replace("\n") }
      fragment.css("p").each { |node| node.replace("#{node.text}\n\n") }

      fragment.text.gsub(/[ \t]+\n/, "\n").gsub(/\n{3,}/, "\n\n").strip.truncate(5000)
    end
  end
end
