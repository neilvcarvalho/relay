class CreateYnabConnections < ActiveRecord::Migration[8.1]
  def change
    create_table :ynab_connections do |t|
      t.references :user, null: false, foreign_key: true, index: { unique: true }
      t.text :access_token, null: false
      t.string :budget_id, null: false
      t.string :budget_name
      t.string :account_id, null: false
      # OAuth-ready columns — nil for personal access token users
      t.text :refresh_token
      t.datetime :expires_at

      t.timestamps
    end
  end
end
