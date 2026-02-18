class AddSeoFieldsToPosts < ActiveRecord::Migration[8.1]
  def change
    add_column :posts, :meta_description, :text
  end
end
