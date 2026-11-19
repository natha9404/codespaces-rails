class RemoveTenants < ActiveRecord::Migration[8.1]
  def change
    remove_index :notification_requests, [:tenant_id, :idempotency_key], unique: true
    remove_reference :notification_requests, :tenant, null: false, foreign_key: true, index: true
    add_index :notification_requests, :idempotency_key, unique: true

    drop_table :tenants do |t|
      t.string :name, null: false
      t.timestamps
    end
  end
end
