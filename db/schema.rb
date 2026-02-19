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

ActiveRecord::Schema[8.1].define(version: 2026_02_19_015524) do
  create_table "action_text_rich_texts", force: :cascade do |t|
    t.text "body"
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.datetime "updated_at", null: false
    t.index ["record_type", "record_id", "name"], name: "index_action_text_rich_texts_uniqueness", unique: true
  end

  create_table "active_storage_attachments", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.string "content_type"
    t.datetime "created_at", null: false
    t.string "filename", null: false
    t.string "key", null: false
    t.text "metadata"
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "categories", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.string "name", null: false
    t.integer "position", default: 0, null: false
    t.string "slug", null: false
    t.datetime "updated_at", null: false
    t.index ["slug"], name: "index_categories_on_slug", unique: true
  end

  create_table "chats", force: :cascade do |t|
    t.string "conversation_type", default: "chat", null: false
    t.datetime "created_at", null: false
    t.integer "model_id"
    t.integer "post_id"
    t.datetime "updated_at", null: false
    t.integer "user_id"
    t.index ["model_id"], name: "index_chats_on_model_id"
    t.index ["post_id", "user_id", "conversation_type"], name: "index_chats_on_post_id_and_user_id_and_conversation_type"
    t.index ["post_id"], name: "index_chats_on_post_id"
    t.index ["user_id"], name: "index_chats_on_user_id"
  end

  create_table "comments", force: :cascade do |t|
    t.boolean "approved", default: true, null: false
    t.text "body", null: false
    t.datetime "created_at", null: false
    t.integer "identity_id", null: false
    t.integer "parent_comment_id"
    t.integer "post_id", null: false
    t.datetime "updated_at", null: false
    t.index ["identity_id"], name: "index_comments_on_identity_id"
    t.index ["parent_comment_id"], name: "index_comments_on_parent_comment_id"
    t.index ["post_id"], name: "index_comments_on_post_id"
  end

  create_table "identities", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "handle"
    t.string "name", null: false
    t.json "settings", default: {}
    t.datetime "updated_at", null: false
    t.index ["handle"], name: "index_identities_on_handle", unique: true
  end

  create_table "loves", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "identity_id", null: false
    t.integer "post_id", null: false
    t.datetime "updated_at", null: false
    t.index ["identity_id"], name: "index_loves_on_identity_id"
    t.index ["post_id", "identity_id"], name: "index_loves_on_post_id_and_identity_id", unique: true
    t.index ["post_id"], name: "index_loves_on_post_id"
  end

  create_table "messages", force: :cascade do |t|
    t.integer "cache_creation_tokens"
    t.integer "cached_tokens"
    t.integer "chat_id", null: false
    t.text "content"
    t.json "content_raw"
    t.datetime "created_at", null: false
    t.integer "input_tokens"
    t.integer "model_id"
    t.integer "output_tokens"
    t.string "role", null: false
    t.text "thinking_signature"
    t.text "thinking_text"
    t.integer "thinking_tokens"
    t.integer "tool_call_id"
    t.datetime "updated_at", null: false
    t.index ["chat_id"], name: "index_messages_on_chat_id"
    t.index ["model_id"], name: "index_messages_on_model_id"
    t.index ["role"], name: "index_messages_on_role"
    t.index ["tool_call_id"], name: "index_messages_on_tool_call_id"
  end

  create_table "models", force: :cascade do |t|
    t.json "capabilities", default: []
    t.integer "context_window"
    t.datetime "created_at", null: false
    t.string "family"
    t.date "knowledge_cutoff"
    t.integer "max_output_tokens"
    t.json "metadata", default: {}
    t.json "modalities", default: {}
    t.datetime "model_created_at"
    t.string "model_id", null: false
    t.string "name", null: false
    t.json "pricing", default: {}
    t.string "provider", null: false
    t.datetime "updated_at", null: false
    t.index ["family"], name: "index_models_on_family"
    t.index ["provider", "model_id"], name: "index_models_on_provider_and_model_id", unique: true
    t.index ["provider"], name: "index_models_on_provider"
  end

  create_table "post_tags", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "post_id", null: false
    t.integer "tag_id", null: false
    t.datetime "updated_at", null: false
    t.index ["post_id", "tag_id"], name: "index_post_tags_on_post_id_and_tag_id", unique: true
    t.index ["post_id"], name: "index_post_tags_on_post_id"
    t.index ["tag_id"], name: "index_post_tags_on_tag_id"
  end

  create_table "post_views", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "ip_hash"
    t.integer "post_id", null: false
    t.string "referrer"
    t.string "source"
    t.datetime "updated_at", null: false
    t.string "user_agent"
    t.index ["created_at"], name: "index_post_views_on_created_at"
    t.index ["post_id", "created_at"], name: "index_post_views_on_post_id_and_created_at"
    t.index ["post_id"], name: "index_post_views_on_post_id"
  end

  create_table "posts", force: :cascade do |t|
    t.integer "category_id"
    t.datetime "created_at", null: false
    t.boolean "featured", default: false, null: false
    t.integer "loves_count", default: 0, null: false
    t.text "meta_description"
    t.datetime "published_at"
    t.integer "reading_time_minutes", default: 0
    t.datetime "scheduled_at"
    t.string "slug", null: false
    t.integer "status", default: 0, null: false
    t.string "subtitle"
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["category_id"], name: "index_posts_on_category_id"
    t.index ["published_at"], name: "index_posts_on_published_at"
    t.index ["slug"], name: "index_posts_on_slug", unique: true
    t.index ["status"], name: "index_posts_on_status"
    t.index ["user_id"], name: "index_posts_on_user_id"
  end

  create_table "sessions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "expires_at", null: false
    t.string "ip_address"
    t.string "token", null: false
    t.datetime "updated_at", null: false
    t.string "user_agent"
    t.integer "user_id", null: false
    t.index ["token"], name: "index_sessions_on_token", unique: true
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "site_settings", force: :cascade do |t|
    t.integer "ai_max_tokens", default: 4096
    t.string "ai_model", default: "claude-sonnet-4-5-20250929"
    t.string "body_font", default: "Source Serif 4"
    t.decimal "body_font_size", precision: 4, scale: 2, default: "1.13"
    t.string "claude_api_key"
    t.datetime "created_at", null: false
    t.string "gemini_api_key"
    t.string "heading_font", default: "Playfair Display"
    t.decimal "heading_font_size", precision: 4, scale: 2, default: "2.25"
    t.string "image_model", default: "imagen-4.0-generate-001"
    t.string "openai_api_key"
    t.text "site_description", default: ""
    t.string "site_name", default: "Prose", null: false
    t.string "subtitle_font", default: "Source Serif 4"
    t.decimal "subtitle_font_size", precision: 4, scale: 2, default: "1.25"
    t.datetime "updated_at", null: false
  end

  create_table "subscribers", force: :cascade do |t|
    t.string "auth_token"
    t.datetime "auth_token_sent_at"
    t.datetime "confirmed_at"
    t.datetime "created_at", null: false
    t.string "email", null: false
    t.integer "identity_id", null: false
    t.datetime "updated_at", null: false
    t.index ["auth_token"], name: "index_subscribers_on_auth_token", unique: true
    t.index ["email"], name: "index_subscribers_on_email", unique: true
    t.index ["identity_id"], name: "index_subscribers_on_identity_id"
  end

  create_table "tags", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.string "slug", null: false
    t.datetime "updated_at", null: false
    t.index ["slug"], name: "index_tags_on_slug", unique: true
  end

  create_table "tool_calls", force: :cascade do |t|
    t.json "arguments", default: {}
    t.datetime "created_at", null: false
    t.integer "message_id", null: false
    t.string "name", null: false
    t.string "thought_signature"
    t.string "tool_call_id", null: false
    t.datetime "updated_at", null: false
    t.index ["message_id"], name: "index_tool_calls_on_message_id"
    t.index ["name"], name: "index_tool_calls_on_name"
    t.index ["tool_call_id"], name: "index_tool_calls_on_tool_call_id", unique: true
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email", null: false
    t.integer "identity_id", null: false
    t.string "password_digest", null: false
    t.integer "role", default: 1, null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["identity_id"], name: "index_users_on_identity_id"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "chats", "models"
  add_foreign_key "chats", "posts"
  add_foreign_key "chats", "users"
  add_foreign_key "comments", "comments", column: "parent_comment_id"
  add_foreign_key "comments", "identities"
  add_foreign_key "comments", "posts"
  add_foreign_key "loves", "identities"
  add_foreign_key "loves", "posts"
  add_foreign_key "messages", "chats"
  add_foreign_key "messages", "models"
  add_foreign_key "messages", "tool_calls"
  add_foreign_key "post_tags", "posts"
  add_foreign_key "post_tags", "tags"
  add_foreign_key "post_views", "posts"
  add_foreign_key "posts", "categories"
  add_foreign_key "posts", "users"
  add_foreign_key "sessions", "users"
  add_foreign_key "subscribers", "identities"
  add_foreign_key "tool_calls", "messages"
  add_foreign_key "users", "identities"
end
