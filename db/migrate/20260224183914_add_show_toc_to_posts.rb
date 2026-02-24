class AddShowTocToPosts < ActiveRecord::Migration[8.1]
  def change
    add_column :posts, :show_toc, :boolean, default: false, null: false
  end
end
