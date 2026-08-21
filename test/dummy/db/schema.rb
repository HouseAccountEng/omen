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

ActiveRecord::Schema[8.1].define(version: 2026_08_21_120002) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  # Custom types defined in this database.
  # Note that some types may not work with other database engines. Be careful if changing database.
  create_enum "booking_status", ["draft", "fulfilled"]
  create_enum "omen_status", ["unstarted", "started", "completed", "failed"]

  create_table "bookings", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "home_id", null: false
    t.enum "status", default: "draft", null: false, enum_type: "booking_status"
    t.string "type"
    t.datetime "updated_at", null: false
    t.index ["home_id"], name: "index_bookings_on_home_id"
  end

  create_table "contacts", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email"
    t.string "name", null: false
    t.text "notes"
    t.string "phone"
    t.string "surname"
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_contacts_on_email", unique: true
  end

  create_table "homes", force: :cascade do |t|
    t.string "apt"
    t.string "city", null: false
    t.bigint "contact_id", null: false
    t.datetime "created_at", null: false
    t.date "occupied_on"
    t.string "street"
    t.datetime "updated_at", null: false
    t.index ["contact_id"], name: "index_homes_on_contact_id"
  end

  create_table "omen_answers", force: :cascade do |t|
    t.jsonb "content", default: [], null: false
    t.datetime "created_at", null: false
    t.string "error"
    t.integer "input_usage", default: 0, null: false
    t.integer "output_usage", default: 0, null: false
    t.jsonb "provenance", default: {}, null: false
    t.bigint "question_id", null: false
    t.jsonb "result", default: [], null: false
    t.string "stop_reason"
    t.datetime "updated_at", null: false
    t.index ["question_id"], name: "index_omen_answers_on_question_id", unique: true
  end

  create_table "omen_questions", force: :cascade do |t|
    t.jsonb "content", default: [], null: false
    t.datetime "created_at", null: false
    t.bigint "reading_id", null: false
    t.datetime "updated_at", null: false
    t.index ["reading_id"], name: "index_omen_questions_on_reading_id"
  end

  create_table "omen_readings", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "input_usage", default: 0, null: false
    t.integer "output_usage", default: 0, null: false
    t.integer "questions_count", default: 0, null: false
    t.enum "status", default: "unstarted", null: false, enum_type: "omen_status"
    t.datetime "updated_at", null: false
  end

  create_table "providers", force: :cascade do |t|
    t.string "access_token"
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.string "secret"
    t.datetime "updated_at", null: false
  end

  add_foreign_key "bookings", "homes"
  add_foreign_key "homes", "contacts"
  add_foreign_key "omen_answers", "omen_questions", column: "question_id"
  add_foreign_key "omen_questions", "omen_readings", column: "reading_id"
end
