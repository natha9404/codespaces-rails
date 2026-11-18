class CreateNotificationRequests < ActiveRecord::Migration[8.1]
  def change
    create_table :notification_requests do |t|
      t.references :tenant, null: false, foreign_key: true
      t.string :idempotency_key, null: false
      t.string :status, null: false
      t.timestamps
    end
    add_index :notification_requests, [:tenant_id, :idempotency_key], unique: true
  end
end