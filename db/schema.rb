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

ActiveRecord::Schema.define(version: 20190708200753) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "answers", id: :bigserial, force: :cascade do |t|
    t.boolean  "correct"
    t.integer  "question_id",         limit: 8
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "text"
    t.text     "text_essay"
    t.text     "comment"
    t.integer  "value_index",         limit: 8
    t.text     "essay_points_earned"
    t.integer  "user_id",             limit: 8
  end

  add_index "answers", ["question_id"], name: "index_answers_on_question_id", using: :btree

  create_table "bash_histories", force: :cascade do |t|
    t.integer  "player_id",    null: false
    t.integer  "instance_id",  null: false
    t.datetime "performed_at", null: false
    t.string   "command",      null: false
    t.integer  "exit_status"
  end

  create_table "clouds", id: :bigserial, force: :cascade do |t|
    t.text     "name"
    t.text     "cidr_block"
    t.text     "driver_id"
    t.integer  "scenario_id", limit: 8,              null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "status",      limit: 8, default: 0
    t.text     "log",                   default: ""
    t.text     "boot_code",             default: ""
  end

  add_index "clouds", ["scenario_id"], name: "index_clouds_on_scenario_id", using: :btree

  create_table "groups", id: :bigserial, force: :cascade do |t|
    t.text     "name"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "scenario_id",  limit: 8,              null: false
    t.text     "instructions",           default: ""
  end

  create_table "instance_groups", id: :bigserial, force: :cascade do |t|
    t.integer  "group_id",      limit: 8,                null: false
    t.integer  "instance_id",   limit: 8,                null: false
    t.boolean  "administrator"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "ip_visible",              default: true
  end

  add_index "instance_groups", ["group_id"], name: "index_instance_groups_on_group_id", using: :btree
  add_index "instance_groups", ["instance_id"], name: "index_instance_groups_on_instance_id", using: :btree

  create_table "instance_roles", id: :bigserial, force: :cascade do |t|
    t.integer  "instance_id", limit: 8, null: false
    t.integer  "role_id",     limit: 8, null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "instance_roles", ["instance_id"], name: "index_instance_roles_on_instance_id", using: :btree
  add_index "instance_roles", ["role_id"], name: "index_instance_roles_on_role_id", using: :btree

  create_table "instances", id: :bigserial, force: :cascade do |t|
    t.text     "name"
    t.text     "ip_address"
    t.text     "driver_id"
    t.text     "os"
    t.boolean  "internet_accessible"
    t.integer  "subnet_id",           limit: 8,              null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "status",              limit: 8, default: 0
    t.text     "scoring_url"
    t.text     "scoring_page"
    t.text     "uuid"
    t.text     "log",                           default: ""
    t.text     "ip_address_dynamic",            default: ""
    t.text     "boot_code",                     default: ""
    t.text     "ip_address_public"
  end

  add_index "instances", ["subnet_id"], name: "index_instances_on_subnet_id", using: :btree

  create_table "players", id: :bigserial, force: :cascade do |t|
    t.text     "login"
    t.text     "password"
    t.integer  "group_id",         limit: 8
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "user_id",          limit: 8
    t.integer  "student_group_id", limit: 8
  end

  add_index "players", ["group_id"], name: "index_players_on_group_id", using: :btree

  create_table "questions", id: :bigserial, force: :cascade do |t|
    t.integer  "scenario_id",    limit: 8, null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "order",          limit: 8
    t.text     "text"
    t.text     "type_of"
    t.text     "options"
    t.text     "values"
    t.integer  "points",         limit: 8
    t.integer  "points_penalty", limit: 8
  end

  add_index "questions", ["scenario_id"], name: "index_questions_on_scenario_id", using: :btree

  create_table "recipes", id: :bigserial, force: :cascade do |t|
    t.integer  "scenario_id", limit: 8, null: false
    t.text     "name"
    t.boolean  "custom"
    t.datetime "created_at",            null: false
    t.datetime "updated_at",            null: false
  end

  create_table "role_recipes", id: :bigserial, force: :cascade do |t|
    t.integer  "role_id",    limit: 8
    t.integer  "recipe_id",  limit: 8, null: false
    t.datetime "created_at",           null: false
    t.datetime "updated_at",           null: false
  end

  add_index "role_recipes", ["recipe_id"], name: "index_role_recipes_on_recipe_id", using: :btree
  add_index "role_recipes", ["role_id"], name: "index_role_recipes_on_role_id", using: :btree

  create_table "roles", id: :bigserial, force: :cascade do |t|
    t.text     "name"
    t.text     "packages"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "scenario_id", limit: 8
  end

  create_table "scenarios", id: :bigserial, force: :cascade do |t|
    t.text     "name"
    t.text     "description"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "status",                limit: 8, default: 0
    t.text     "log",                             default: ""
    t.text     "answers",                         default: ""
    t.text     "uuid"
    t.text     "scoring_pages"
    t.text     "answers_url"
    t.text     "scoring_pages_content",           default: ""
    t.integer  "user_id",               limit: 8
    t.text     "com_page"
    t.boolean  "modified",                        default: false
    t.text     "instructions",                    default: ""
    t.text     "instructions_student",            default: ""
    t.integer  "location",              limit: 8, default: 0
    t.boolean  "modifiable",                      default: false
    t.text     "boot_code",                       default: ""
    t.boolean  "archived",                        default: false, null: false
  end

  create_table "schedules", id: :bigserial, force: :cascade do |t|
    t.integer  "user_id",           limit: 8
    t.text     "scenario"
    t.text     "scenario_location"
    t.text     "uuid"
    t.datetime "start_time"
    t.datetime "end_time"
    t.datetime "created_at",                  null: false
    t.datetime "updated_at",                  null: false
  end

  create_table "statistics", id: :bigserial, force: :cascade do |t|
    t.integer  "user_id",             limit: 8
    t.datetime "created_at",                                 null: false
    t.datetime "updated_at",                                 null: false
    t.text     "bash_histories",                default: ""
    t.text     "bash_analytics"
    t.text     "scenario_name"
    t.datetime "scenario_created_at"
    t.text     "script_log",                    default: ""
    t.text     "exit_status",                   default: ""
    t.integer  "scenario_id",         limit: 8
    t.text     "resource_info"
  end

  create_table "student_group_users", id: :bigserial, force: :cascade do |t|
    t.integer  "student_group_id", limit: 8
    t.integer  "user_id",          limit: 8
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "student_groups", id: :bigserial, force: :cascade do |t|
    t.integer  "user_id",           limit: 8,              null: false
    t.text     "name",                        default: "", null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "registration_code"
  end

  create_table "subnets", id: :bigserial, force: :cascade do |t|
    t.text     "name"
    t.text     "cidr_block"
    t.text     "driver_id"
    t.boolean  "internet_accessible",           default: false
    t.integer  "cloud_id",            limit: 8,                 null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "status",              limit: 8, default: 0
    t.text     "log",                           default: ""
    t.text     "boot_code",                     default: ""
  end

  add_index "subnets", ["cloud_id"], name: "index_subnets_on_cloud_id", using: :btree

  create_table "tutorials", id: :bigserial, force: :cascade do |t|
    t.text     "title"
    t.text     "text"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "users", id: :bigserial, force: :cascade do |t|
    t.text     "email",                            default: "", null: false
    t.text     "encrypted_password",               default: "", null: false
    t.text     "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",          limit: 8, default: 0,  null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.text     "current_sign_in_ip"
    t.text     "last_sign_in_ip"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "name",                                          null: false
    t.integer  "role",                   limit: 8
    t.text     "organization"
    t.text     "registration_code"
  end

  add_index "users", ["email"], name: "index_users_on_email", unique: true, using: :btree
  add_index "users", ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true, using: :btree

  create_table "variable_templates", force: :cascade do |t|
    t.integer "group_id"
    t.integer "scenario_id"
    t.string  "name",        null: false
    t.string  "type",        null: false
    t.string  "value"
  end

  add_index "variable_templates", ["group_id", "name"], name: "index_variable_templates_on_group_id_and_name", unique: true, using: :btree
  add_index "variable_templates", ["scenario_id", "name"], name: "index_variable_templates_on_scenario_id_and_name", unique: true, using: :btree

  create_table "variables", force: :cascade do |t|
    t.integer "variable_template_id", null: false
    t.integer "player_id"
    t.integer "scenario_id"
    t.string  "value",                null: false
  end

  add_index "variables", ["variable_template_id", "player_id"], name: "index_variables_on_variable_template_id_and_player_id", unique: true, using: :btree
  add_index "variables", ["variable_template_id", "scenario_id"], name: "index_variables_on_variable_template_id_and_scenario_id", unique: true, using: :btree

  add_foreign_key "bash_histories", "instances", name: "fk_bash_histories_instances"
  add_foreign_key "bash_histories", "players", name: "fk_bash_histories_players"
  add_foreign_key "clouds", "scenarios", name: "fk_clouds_scenarios", on_delete: :cascade
  add_foreign_key "groups", "scenarios", name: "fk_groups_scenarios", on_delete: :cascade
  add_foreign_key "instance_groups", "groups", name: "fk_instance_groups_groups", on_delete: :cascade
  add_foreign_key "instance_groups", "instances", name: "fk_instance_groups_instances", on_delete: :cascade
  add_foreign_key "instance_roles", "instances", name: "fk_instance_roles_instances", on_delete: :cascade
  add_foreign_key "instance_roles", "roles", name: "fk_instance_roles_roles", on_delete: :cascade
  add_foreign_key "instances", "subnets", name: "fk_instances_subnets", on_delete: :cascade
  add_foreign_key "players", "groups", name: "fk_players_groups", on_delete: :cascade
  add_foreign_key "players", "student_groups", name: "fk_players_student_groups", on_delete: :nullify
  add_foreign_key "players", "users", name: "fk_players_users", on_delete: :nullify
  add_foreign_key "questions", "scenarios", name: "fk_questions_scenarios", on_delete: :cascade
  add_foreign_key "recipes", "scenarios", name: "fk_recipes_scenarios", on_delete: :cascade
  add_foreign_key "role_recipes", "recipes", name: "fk_role_recipes_recipes", on_delete: :cascade
  add_foreign_key "statistics", "scenarios", on_delete: :nullify
  add_foreign_key "subnets", "clouds", name: "fk_subnets_clouds", on_delete: :cascade
  add_foreign_key "variable_templates", "groups", on_delete: :cascade
  add_foreign_key "variable_templates", "scenarios", on_delete: :cascade
  add_foreign_key "variables", "players", on_delete: :cascade
  add_foreign_key "variables", "scenarios", on_delete: :cascade
  add_foreign_key "variables", "variable_templates", on_delete: :cascade
end
