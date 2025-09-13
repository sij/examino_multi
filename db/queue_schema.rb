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

ActiveRecord::Schema[8.0].define(version: 2025_09_12_183210) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "g1_details", force: :cascade do |t|
    t.integer "bet_point_id", null: false
    t.string "csmf_cod"
    t.date "data"
    t.integer "num_term"
    t.integer "cod_tipo_gioco"
    t.integer "cod_tipo_conc"
    t.string "des_gioco"
    t.integer "num_emesso"
    t.integer "impo_emesso"
    t.integer "num_pagato"
    t.integer "impo_pagato"
    t.string "tipologia"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "owner_id", null: false
    t.index ["owner_id"], name: "index_g1_details_on_owner_id"
  end

  create_table "owners", id: :serial, force: :cascade do |t|
    t.string "name"
    t.string "gruppo"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "roles", force: :cascade do |t|
    t.string "name"
    t.string "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "self_advances", force: :cascade do |t|
    t.integer "num_term"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "sessions", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "ip_address"
    t.string "user_agent"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "solid_cache_entries", force: :cascade do |t|
    t.binary "key", null: false
    t.binary "value", null: false
    t.datetime "created_at", null: false
    t.bigint "key_hash", null: false
    t.integer "byte_size", null: false
    t.index ["byte_size"], name: "index_solid_cache_entries_on_byte_size"
    t.index ["key_hash", "byte_size"], name: "index_solid_cache_entries_on_key_hash_and_byte_size"
    t.index ["key_hash"], name: "index_solid_cache_entries_on_key_hash", unique: true
  end

  create_table "users", force: :cascade do |t|
    t.string "email_address", null: false
    t.string "password_digest", null: false
    t.string "info"
    t.string "name"
    t.boolean "enabled", default: true
    t.bigint "bet_point_id"
    t.bigint "role_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "login_ip"
    t.datetime "login_at"
    t.bigint "owner_id", null: false
    t.index ["bet_point_id"], name: "index_users_on_bet_point_id"
    t.index ["email_address"], name: "index_users_on_email_address", unique: true
    t.index ["name"], name: "index_users_on_name", unique: true
    t.index ["owner_id"], name: "index_users_on_owner_id"
    t.index ["role_id"], name: "index_users_on_role_id"
  end

  add_foreign_key "g1_details", "owners"
  add_foreign_key "sessions", "users"
  add_foreign_key "users", "owners"
  add_foreign_key "users", "roles"
end
