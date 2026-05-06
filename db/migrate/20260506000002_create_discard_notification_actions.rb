class CreateDiscardNotificationActions < ActiveRecord::Migration[8.1]
  def change
    create_table :discard_notification_actions do |t|
      t.timestamps
    end
  end
end
