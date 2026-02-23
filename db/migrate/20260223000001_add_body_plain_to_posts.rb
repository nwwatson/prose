class AddBodyPlainToPosts < ActiveRecord::Migration[8.1]
  def change
    add_column :posts, :body_plain, :text
  end
end
