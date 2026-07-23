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

ActiveRecord::Schema[8.1].define(version: 2026_07_23_090000) do
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

  create_table "photos", force: :cascade do |t|
    t.text "caption_en"
    t.text "caption_es"
    t.datetime "created_at", null: false
    t.integer "position", null: false
    t.boolean "published", default: true, null: false
    t.string "title_en"
    t.string "title_es"
    t.datetime "updated_at", null: false
    t.index ["position"], name: "index_photos_on_position", unique: true
  end

  create_table "post_generations", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "failure_reason"
    t.string "generation_model"
    t.integer "post_id"
    t.string "source_locale", null: false
    t.string "status", default: "queued", null: false
    t.text "transcript"
    t.string "transcription_model"
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["post_id"], name: "index_post_generations_on_post_id"
    t.index ["status"], name: "index_post_generations_on_status"
    t.index ["user_id"], name: "index_post_generations_on_user_id"
  end

  create_table "post_translations", force: :cascade do |t|
    t.text "content"
    t.datetime "created_at", null: false
    t.string "description"
    t.string "locale", null: false
    t.integer "post_id", null: false
    t.boolean "published"
    t.datetime "published_at"
    t.string "title"
    t.datetime "updated_at", null: false
    t.index ["post_id", "locale"], name: "index_post_translations_on_post_id_and_locale", unique: true
    t.index ["post_id"], name: "index_post_translations_on_post_id"
  end

  create_table "posts", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.boolean "published", default: false, null: false
    t.datetime "published_at"
    t.datetime "updated_at", null: false
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
    t.index ["email_address"], name: "index_users_on_email_address", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "post_generations", "posts", on_delete: :nullify
  add_foreign_key "post_generations", "users"
  add_foreign_key "post_translations", "posts"
  add_foreign_key "sessions", "users"
end
