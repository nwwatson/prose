class AddEditDeleteAndNotifyToComments < ActiveRecord::Migration[8.1]
  def change
    add_column :comments, :edited_at, :datetime
    add_column :comments, :deleted_at, :datetime
    add_column :comments, :notify_on_reply, :boolean, default: false, null: false
  end
end
