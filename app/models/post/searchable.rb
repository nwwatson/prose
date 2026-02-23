module Post::Searchable
  extend ActiveSupport::Concern

  included do
    before_save :update_body_plain

    scope :search, ->(query) {
      return none if query.blank?

      sanitized = klass.send(:fts_query, query)
      where("id IN (SELECT rowid FROM posts_fts WHERE posts_fts MATCH ?)", sanitized)
        .order(Arel.sql("(SELECT rank FROM posts_fts WHERE posts_fts MATCH #{connection.quote(sanitized)} AND rowid = posts.id)"))
    }
  end

  class_methods do
    def search_with_snippets(query)
      return {} if query.blank?

      sanitized = fts_query(query)
      sql = sanitize_sql_array([
        <<~SQL, sanitized, 100
          SELECT
            rowid,
            snippet(posts_fts, 0, '<mark>', '</mark>', '...', 32) AS title_snippet,
            snippet(posts_fts, 1, '<mark>', '</mark>', '...', 32) AS subtitle_snippet,
            snippet(posts_fts, 2, '<mark>', '</mark>', '...', 32) AS body_snippet
          FROM posts_fts
          WHERE posts_fts MATCH ?
          ORDER BY rank
          LIMIT ?
        SQL
      ])
      results = connection.select_all(sql)

      results.each_with_object({}) do |row, hash|
        hash[row["rowid"].to_i] = Post::SearchResult.new(
          title_snippet: row["title_snippet"],
          subtitle_snippet: row["subtitle_snippet"],
          body_snippet: row["body_snippet"]
        )
      end
    end

    private

    def fts_query(query)
      tokens = query.to_s.strip.split(/\s+/).map { |t| %("#{t.gsub('"', '""')}") }
      tokens[-1] = tokens[-1] + "*" if tokens.any?
      tokens.join(" ")
    end
  end

  private

  def update_body_plain
    self.body_plain = content&.to_plain_text.to_s
  end
end
