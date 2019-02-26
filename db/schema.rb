# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20190215090344) do

  create_table "answers", force: :cascade do |t|
    t.boolean  "correct"
    t.integer  "question_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "text"
    t.text     "text_essay"
    t.text     "comment"
    t.integer  "value_index"
    t.string   "essay_points_earned"
    t.integer  "user_id"
  end

  add_index "answers", ["question_id"], name: "index_answers_on_question_id"

  create_table "clouds", force: :cascade do |t|
    t.string   "name"
    t.string   "cidr_block"
    t.string   "driver_id"
    t.integer  "scenario_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "status",      default: 0
    t.string   "log",         default: ""
    t.string   "boot_code",   default: ""
  end

  add_index "clouds", ["scenario_id"], name: "index_clouds_on_scenario_id"

  create_table "groups", force: :cascade do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "scenario_id"
    t.text     "instructions", default: ""
    t.string   "variables"
  end

  create_table "instance_groups", force: :cascade do |t|
    t.integer  "group_id"
    t.integer  "instance_id"
    t.boolean  "administrator"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "ip_visible",    default: true
  end

  add_index "instance_groups", ["group_id"], name: "index_instance_groups_on_group_id"
  add_index "instance_groups", ["instance_id"], name: "index_instance_groups_on_instance_id"

  create_table "instance_roles", force: :cascade do |t|
    t.integer  "instance_id"
    t.integer  "role_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "instance_roles", ["instance_id"], name: "index_instance_roles_on_instance_id"
  add_index "instance_roles", ["role_id"], name: "index_instance_roles_on_role_id"

  create_table "instances", force: :cascade do |t|
    t.string   "name"
    t.string   "ip_address"
    t.string   "driver_id"
    t.string   "cookbook_url"
    t.string   "os"
    t.boolean  "internet_accessible"
    t.integer  "subnet_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "status",              default: 0
    t.string   "scoring_url"
    t.string   "scoring_page"
    t.string   "uuid"
    t.string   "com_page"
    t.string   "log",                 default: ""
    t.string   "bash_history_page",   default: ""
    t.string   "exit_status_page",    default: ""
    t.string   "script_log_page",     default: ""
    t.string   "ip_address_dynamic",  default: ""
    t.string   "boot_code",           default: ""
    t.string   "ip_address_public"
  end

  add_index "instances", ["subnet_id"], name: "index_instances_on_subnet_id"

  create_table "players", force: :cascade do |t|
    t.string   "login"
    t.string   "password"
    t.integer  "group_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "user_id"
    t.integer  "student_group_id"
  end

  add_index "players", ["group_id"], name: "index_players_on_group_id"

  create_table "questions", force: :cascade do |t|
    t.integer  "scenario_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "order"
    t.string   "text"
    t.string   "type_of"
    t.string   "options",        default: "--- []\n"
    t.string   "values"
    t.integer  "points"
    t.integer  "points_penalty"
  end

  add_index "questions", ["scenario_id"], name: "index_questions_on_scenario_id"

  create_table "recipes", force: :cascade do |t|
    t.integer  "scenario_id"
    t.string   "name"
    t.boolean  "custom"
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
  end

  create_table "role_recipes", force: :cascade do |t|
    t.integer  "role_id"
    t.integer  "recipe_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_index "role_recipes", ["recipe_id"], name: "index_role_recipes_on_recipe_id"
  add_index "role_recipes", ["role_id"], name: "index_role_recipes_on_role_id"

  create_table "roles", force: :cascade do |t|
    t.string   "name"
    t.string   "packages"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "scenario_id"
  end

  create_table "scenarios", force: :cascade do |t|
    t.string   "name"
    t.string   "description"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "status",                default: 0
    t.text     "log",                   default: ""
    t.string   "answers",               default: ""
    t.string   "uuid"
    t.string   "scoring_pages"
    t.string   "answers_url"
    t.text     "scoring_pages_content", default: ""
    t.integer  "user_id"
    t.string   "com_page"
    t.boolean  "modified",              default: false
    t.text     "instructions",          default: ""
    t.text     "instructions_student",  default: ""
    t.integer  "location",              default: 0
    t.boolean  "modifiable",            default: false
    t.string   "aws_prefixes"
    t.string   "boot_code",             default: ""
  end

  create_table "schedules", force: :cascade do |t|
    t.integer  "user_id"
    t.string   "scenario"
    t.string   "scenario_location"
    t.string   "uuid"
    t.datetime "start_time"
    t.datetime "end_time"
    t.datetime "created_at",        null: false
    t.datetime "updated_at",        null: false
  end

  create_table "statistics", force: :cascade do |t|
    t.integer  "user_id"
    t.datetime "created_at",                               null: false
    t.datetime "updated_at",                               null: false
    t.string   "bash_histories",      default: ""
    t.text     "bash_analytics",      default: "--- []\n"
    t.string   "scenario_name"
    t.datetime "scenario_created_at"
    t.string   "script_log",          default: ""
    t.string   "exit_status",         default: ""
    t.integer  "scenario_id"
    t.string   "resource_info"
  end

  add_foreign_key "statistics", "scenarios", on_delete: :nullify

  create_table "student_group_users", force: :cascade do |t|
    t.integer  "student_group_id"
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "student_groups", force: :cascade do |t|
    t.integer  "user_id",                        null: false
    t.string   "name",              default: "", null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "registration_code"
  end

  create_table "subnets", force: :cascade do |t|
    t.string   "name"
    t.string   "cidr_block"
    t.string   "driver_id"
    t.boolean  "internet_accessible", default: false
    t.integer  "cloud_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "status",              default: 0
    t.string   "log",                 default: ""
    t.string   "boot_code",           default: ""
  end

  add_index "subnets", ["cloud_id"], name: "index_subnets_on_cloud_id"

  create_table "tutorials", force: :cascade do |t|
    t.string   "title"
    t.text     "text"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "users", force: :cascade do |t|
    t.string   "email",                  default: "", null: false
    t.string   "encrypted_password",     default: "", null: false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",          default: 0,  null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "name",                                null: false
    t.integer  "role"
    t.string   "organization"
    t.string   "registration_code"
  end

  add_index "users", ["email"], name: "index_users_on_email", unique: true
  add_index "users", ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true

end
