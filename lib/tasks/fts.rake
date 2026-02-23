# Strip FTS5 shadow tables from structure.sql after dump.
#
# SQLite auto-creates shadow tables (e.g. posts_fts_data, posts_fts_idx)
# when a VIRTUAL TABLE ... USING fts5() is created. If the dump includes
# explicit CREATE TABLE statements for these, loading the structure fails
# because the shadow tables already exist from the virtual table creation.
Rake::Task["db:schema:dump"].enhance do
  structure_file = Rails.root.join("db/structure.sql")
  next unless structure_file.exist?

  content = structure_file.read
  cleaned = content.gsub(/^CREATE TABLE IF NOT EXISTS '#{Regexp.escape("posts_fts")}_\w+'.*;\n/, "")

  if cleaned != content
    structure_file.write(cleaned)
    puts "Stripped FTS5 shadow tables from structure.sql"
  end
end
