# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_05_04_015453) do
  create_table "notifications", force: :cascade do |t|
    t.string "app_name"
    t.datetime "created_at", null: false
    t.text "error_message"
    t.text "raw_payload", null: false
    t.integer "status", default: 0, null: false
    t.text "text"
    t.string "title"
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["status"], name: "index_notifications_on_status"
    t.index ["user_id", "created_at"], name: "index_notifications_on_user_id_and_created_at"
    t.index ["user_id"], name: "index_notifications_on_user_id"
  end

  create_table "sessions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "ip_address"
    t.datetime "updated_at", null: false
    t.string "user_agent"
    t.integer "user_id", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email_address", null: false
    t.string "password_digest", null: false
    t.datetime "updated_at", null: false
    t.string "webhook_token", default: "", null: false
    t.index ["email_address"], name: "index_users_on_email_address", unique: true
    t.index ["webhook_token"], name: "index_users_on_webhook_token", unique: true
  end

  create_table "ynab_connections", force: :cascade do |t|
    t.text "access_token", null: false
    t.string "account_id", null: false
    t.string "budget_id", null: false
    t.string "budget_name"
    t.datetime "created_at", null: false
    t.datetime "expires_at"
    t.text "refresh_token"
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["user_id"], name: "index_ynab_connections_on_user_id", unique: true
  end

  add_foreign_key "notifications", "users"
  add_foreign_key "sessions", "users"
  add_foreign_key "ynab_connections", "users"
end
