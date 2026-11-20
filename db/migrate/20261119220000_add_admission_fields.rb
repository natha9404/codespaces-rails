class AddAdmissionFields < ActiveRecord::Migration[8.1]
  def change
    change_table :notification_requests do |t|
      t.string :notification_type
      t.string :priority, null: false, default: "standard"
      t.string :decision_reason
      t.text :context_ciphertext
    end

    change_table :notification_deliveries do |t|
      t.string :recipient_lookup_hash
      t.string :provider_message_id
      t.string :decision_reason
    end

    add_index :notification_deliveries, [:notification_request_id, :channel],
              unique: true, name: "index_notification_deliveries_on_request_and_channel"
  end
end
