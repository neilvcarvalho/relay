class CreateNotificationRules < ActiveRecord::Migration[8.1]
  def change
    create_table :notification_rules do |t|
      t.references :user, null: false, foreign_key: true
      t.integer    :position,         null: false, default: 0
      t.string     :description
      t.boolean    :active,           null: false, default: true
      t.string     :app_name,         null: false
      t.integer    :matcher_type,     null: false
      t.string     :text_pattern
      t.text       :llm_instructions
      t.string     :action_type,      null: false
      t.integer    :action_id,        null: false
      t.timestamps

      t.index [ :user_id, :app_name, :position ], unique: true
      t.index [ :action_type, :action_id ]
    end
  end
end
