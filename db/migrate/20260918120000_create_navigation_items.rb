class CreateNavigationItems < ActiveRecord::Migration[8.1]
  def up
    create_table :navigation_items do |t|
      t.string :label, null: false
      t.string :url, null: false
      t.integer :location, null: false, default: 0
      t.integer :position, null: false, default: 0
      t.boolean :open_in_new_tab, null: false, default: false

      t.timestamps
    end

    add_index :navigation_items, [ :location, :position ]

    seed_header_from_pages

    remove_column :pages, :show_in_navigation
    remove_column :pages, :position
  end

  def down
    add_column :pages, :show_in_navigation, :boolean, default: false, null: false
    add_column :pages, :position, :integer, default: 0, null: false
    drop_table :navigation_items
  end

  private

  # Carries the previously hardcoded "Home" link and every page that had
  # show_in_navigation checked over as header items, so the public header
  # looks the same immediately after upgrading.
  def seed_header_from_pages
    now = connection.quote(Time.current)
    rows = [ [ "Home", "/" ] ]
    rows += select_rows(<<~SQL)
      SELECT title, '/' || slug FROM pages
      WHERE show_in_navigation = 1 AND status = 1 ORDER BY position, title
    SQL

    rows.each_with_index do |(label, url), index|
      execute <<~SQL
        INSERT INTO navigation_items (label, url, location, position, open_in_new_tab, created_at, updated_at)
        VALUES (#{connection.quote(label)}, #{connection.quote(url)}, 0, #{index}, 0, #{now}, #{now})
      SQL
    end
  end
end
