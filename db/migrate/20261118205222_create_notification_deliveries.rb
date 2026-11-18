class CreateNotificationDeliveries < ActiveRecord::Migration[8.1]
  def change
    create_table :notification_deliveries do |t|
      t.references :notification_request, null: false, foreign_key: true
      t.string :channel, null: false
      t.string :status, null: false
      t.timestamps
    end
  end
end