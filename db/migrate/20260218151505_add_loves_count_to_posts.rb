class AddLovesCountToPosts < ActiveRecord::Migration[8.1]
  def change
    add_column :posts, :loves_count, :integer, null: false, default: 0
  end
end
