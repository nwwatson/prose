class AddEmailFrequencyToSubscribers < ActiveRecord::Migration[8.1]
  def change
    add_column :subscribers, :email_frequency, :integer, default: 0, null: false
    add_column :subscribers, :last_digest_at, :datetime
    add_index :subscribers, :email_frequency
  end
end
