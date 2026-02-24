class GenerateHandlesForExistingUsers < ActiveRecord::Migration[8.1]
  def up
    execute <<~SQL
      UPDATE identities
      SET handle = LOWER(REPLACE(REPLACE(TRIM(name), ' ', '_'), '-', '_'))
      WHERE handle IS NULL
        AND id IN (SELECT identity_id FROM users)
    SQL

    # Resolve any duplicate handles by appending a numeric suffix
    duplicates = execute("SELECT handle, COUNT(*) as cnt FROM identities WHERE handle IS NOT NULL GROUP BY handle HAVING cnt > 1")
    duplicates.each do |row|
      ids = execute("SELECT id FROM identities WHERE handle = '#{row["handle"]}' ORDER BY id")
      ids.each_with_index do |id_row, index|
        next if index == 0
        execute("UPDATE identities SET handle = '#{row["handle"]}_#{index + 1}' WHERE id = #{id_row["id"]}")
      end
    end
  end

  def down
    # No-op: we can't know which handles were auto-generated
  end
end
