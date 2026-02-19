class AddPostAndUserToChats < ActiveRecord::Migration[8.1]
  def change
    add_reference :chats, :post, foreign_key: true
    add_reference :chats, :user, foreign_key: true
    add_column :chats, :conversation_type, :string, default: "chat", null: false

    add_index :chats, [ :post_id, :user_id, :conversation_type ]
  end
end
