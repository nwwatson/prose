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

ActiveRecord::Schema[8.1].define(version: 2026_01_02_032028) do
  create_table "accounts", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_accounts_on_name"
  end

  create_table "publications", force: :cascade do |t|
    t.integer "account_id", null: false
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.text "custom_css"
    t.string "custom_domain"
    t.text "description"
    t.string "language", default: "en"
    t.string "name", null: false
    t.text "settings"
    t.string "slug", null: false
    t.text "social_links"
    t.text "tagline"
    t.string "timezone", default: "UTC"
    t.datetime "updated_at", null: false
    t.index ["account_id", "active"], name: "index_publications_on_account_id_and_active"
    t.index ["account_id"], name: "index_publications_on_account_id"
    t.index ["custom_domain"], name: "index_publications_on_custom_domain", unique: true
    t.index ["slug"], name: "index_publications_on_slug", unique: true
  end

  add_foreign_key "publications", "accounts", on_delete: :cascade
end
