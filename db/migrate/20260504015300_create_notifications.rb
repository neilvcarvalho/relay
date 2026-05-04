class CreateNotifications < ActiveRecord::Migration[8.1]
  def change
    create_table :notifications do |t|
      t.references :user, null: false, foreign_key: true
      t.string :app_name
      t.string :title
      t.text :text
      t.text :raw_payload, null: false
      t.integer :status, null: false, default: 0
      t.text :error_message

      t.timestamps
    end

    add_index :notifications, [ :user_id, :created_at ]
    add_index :notifications, :status
  end
end
