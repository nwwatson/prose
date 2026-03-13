class AddVisibilityToPosts < ActiveRecord::Migration[8.1]
  def change
    add_column :posts, :visibility, :integer, null: false, default: 0
  end
end
