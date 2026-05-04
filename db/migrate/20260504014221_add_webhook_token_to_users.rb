class AddWebhookTokenToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :webhook_token, :string, null: false, default: ""
    add_index :users, :webhook_token, unique: true
  end
end
