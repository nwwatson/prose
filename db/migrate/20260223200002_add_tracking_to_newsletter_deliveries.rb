class AddTrackingToNewsletterDeliveries < ActiveRecord::Migration[8.1]
  def change
    add_column :newsletter_deliveries, :opened_at, :datetime
    add_column :newsletter_deliveries, :clicked_at, :datetime
    add_column :newsletter_deliveries, :bounced_at, :datetime
    add_column :newsletter_deliveries, :open_count, :integer, default: 0
  end
end
