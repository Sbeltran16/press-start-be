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

ActiveRecord::Schema[7.1].define(version: 2025_06_20_100427) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "backlog_games", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "igdb_game_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id", "igdb_game_id"], name: "index_backlog_games_on_user_id_and_igdb_game_id", unique: true
    t.index ["user_id"], name: "index_backlog_games_on_user_id"
  end

  create_table "favorite_games", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "igdb_game_id"
    t.integer "position"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_favorite_games_on_user_id"
  end

  create_table "follows", force: :cascade do |t|
    t.integer "follower_id", null: false
    t.integer "followed_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["follower_id", "followed_id"], name: "index_follows_on_follower_id_and_followed_id", unique: true
  end

  create_table "game_likes", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "igdb_game_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id", "igdb_game_id"], name: "index_game_likes_on_user_id_and_igdb_game_id", unique: true
    t.index ["user_id"], name: "index_game_likes_on_user_id"
  end

  create_table "game_list_items", force: :cascade do |t|
    t.bigint "game_list_id", null: false
    t.bigint "igdb_game_id", null: false
    t.integer "position", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["game_list_id", "igdb_game_id"], name: "index_game_list_items_on_game_list_id_and_igdb_game_id", unique: true
    t.index ["game_list_id", "position"], name: "index_game_list_items_on_game_list_id_and_position"
    t.index ["game_list_id"], name: "index_game_list_items_on_game_list_id"
  end

  create_table "game_lists", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "name", null: false
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id", "name"], name: "index_game_lists_on_user_id_and_name", unique: true
    t.index ["user_id"], name: "index_game_lists_on_user_id"
  end

  create_table "game_plays", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "igdb_game_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id", "igdb_game_id"], name: "index_game_plays_on_user_id_and_igdb_game_id", unique: true
    t.index ["user_id"], name: "index_game_plays_on_user_id"
  end

  create_table "game_views", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.integer "igdb_game_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_game_views_on_user_id"
  end

  create_table "list_likes", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "game_list_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["game_list_id"], name: "index_list_likes_on_game_list_id"
    t.index ["user_id", "game_list_id"], name: "index_list_likes_on_user_id_and_game_list_id", unique: true
    t.index ["user_id"], name: "index_list_likes_on_user_id"
  end

  create_table "ratings", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "igdb_game_id"
    t.float "rating"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id", "igdb_game_id"], name: "index_ratings_on_user_id_and_igdb_game_id", unique: true
    t.index ["user_id"], name: "index_ratings_on_user_id"
  end

  create_table "review_comments", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "review_id", null: false
    t.text "content", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["review_id"], name: "index_review_comments_on_review_id"
    t.index ["user_id"], name: "index_review_comments_on_user_id"
  end

  create_table "review_likes", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "review_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["review_id"], name: "index_review_likes_on_review_id"
    t.index ["user_id", "review_id"], name: "index_review_likes_on_user_id_and_review_id", unique: true
    t.index ["user_id"], name: "index_review_likes_on_user_id"
  end

  create_table "reviews", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "igdb_game_id"
    t.float "rating"
    t.text "comment"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id", "igdb_game_id"], name: "index_reviews_on_user_id_and_igdb_game_id", unique: true
    t.index ["user_id"], name: "index_reviews_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "jti", null: false
    t.string "username"
    t.text "bio"
    t.integer "favorite_game_ids", default: [], array: true
    t.string "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.string "location"
    t.index "lower((username)::text)", name: "index_users_on_lower_username", unique: true
    t.index ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["jti"], name: "index_users_on_jti", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "backlog_games", "users"
  add_foreign_key "favorite_games", "users"
  add_foreign_key "follows", "users", column: "followed_id"
  add_foreign_key "follows", "users", column: "follower_id"
  add_foreign_key "game_likes", "users"
  add_foreign_key "game_list_items", "game_lists"
  add_foreign_key "game_lists", "users"
  add_foreign_key "game_plays", "users"
  add_foreign_key "game_views", "users"
  add_foreign_key "list_likes", "game_lists"
  add_foreign_key "list_likes", "users"
  add_foreign_key "ratings", "users"
  add_foreign_key "review_comments", "reviews"
  add_foreign_key "review_comments", "users"
  add_foreign_key "review_likes", "reviews"
  add_foreign_key "review_likes", "users"
  add_foreign_key "reviews", "users"
end
