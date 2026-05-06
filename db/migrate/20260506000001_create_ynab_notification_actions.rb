class CreateYnabNotificationActions < ActiveRecord::Migration[8.1]
  def change
    create_table :ynab_notification_actions do |t|
      t.string :account_id,   null: false
      t.string :account_name
      t.timestamps
    end
  end
end
