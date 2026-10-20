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

ActiveRecord::Schema[8.1].define(version: 2026_10_20_194548) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "attempts", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "question_id", null: false
    t.string "outcome", null: false
    t.string "answer"
    t.jsonb "rating_changes", default: [], null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["question_id"], name: "index_attempts_on_question_id"
    t.index ["user_id", "created_at"], name: "index_attempts_on_user_id_and_created_at"
    t.index ["user_id"], name: "index_attempts_on_user_id"
  end

  create_table "categories", force: :cascade do |t|
    t.string "name", null: false
    t.string "kind", default: "tag", null: false
    t.integer "questions_count", default: 0, null: false
    t.string "mongo_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["kind"], name: "index_categories_on_kind"
    t.index ["mongo_id"], name: "index_categories_on_mongo_id", unique: true
    t.index ["name"], name: "index_categories_on_name", unique: true
  end

  create_table "question_ratings", force: :cascade do |t|
    t.bigint "question_id", null: false
    t.bigint "category_id", null: false
    t.float "rating", default: 1200.0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["category_id", "rating"], name: "index_question_ratings_on_category_id_and_rating"
    t.index ["question_id", "category_id"], name: "index_question_ratings_on_question_id_and_category_id", unique: true
  end

  create_table "questions", force: :cascade do |t|
    t.text "body", null: false
    t.string "correct_answer", null: false
    t.jsonb "wrong_answers", default: [], null: false
    t.string "picture_url"
    t.integer "answered_count", default: 0, null: false
    t.integer "correct_count", default: 0, null: false
    t.integer "passed_count", default: 0, null: false
    t.jsonb "wrong_counts", default: {}, null: false
    t.bigint "creator_id"
    t.string "mongo_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["creator_id"], name: "index_questions_on_creator_id"
    t.index ["mongo_id"], name: "index_questions_on_mongo_id", unique: true
  end

  create_table "sessions", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "ip_address"
    t.string "user_agent"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "user_ratings", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "category_id", null: false
    t.float "rating", default: 1200.0, null: false
    t.integer "answered_count", default: 0, null: false
    t.integer "correct_count", default: 0, null: false
    t.integer "wrong_count", default: 0, null: false
    t.integer "passed_count", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["category_id", "rating"], name: "index_user_ratings_on_category_id_and_rating"
    t.index ["user_id", "category_id"], name: "index_user_ratings_on_user_id_and_category_id", unique: true
  end

  create_table "users", force: :cascade do |t|
    t.string "email_address", null: false
    t.string "password_digest", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "display_name"
    t.index ["email_address"], name: "index_users_on_email_address", unique: true
  end

  add_foreign_key "attempts", "questions"
  add_foreign_key "attempts", "users"
  add_foreign_key "question_ratings", "categories"
  add_foreign_key "question_ratings", "questions"
  add_foreign_key "questions", "users", column: "creator_id"
  add_foreign_key "sessions", "users"
  add_foreign_key "user_ratings", "categories"
  add_foreign_key "user_ratings", "users"
end
