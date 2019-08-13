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

ActiveRecord::Schema.define(version: 2019_08_11_071316) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "answers", force: :cascade do |t|
    t.boolean "correct"
    t.bigint "question_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text "text"
    t.text "text_essay"
    t.text "comment"
    t.bigint "value_index"
    t.text "essay_points_earned"
    t.bigint "user_id"
    t.index ["question_id"], name: "index_answers_on_question_id"
  end

  create_table "bash_histories", id: :serial, force: :cascade do |t|
    t.integer "player_id", null: false
    t.integer "instance_id", null: false
    t.datetime "performed_at", null: false
    t.string "command", null: false
    t.integer "exit_status"
  end

  create_table "clouds", force: :cascade do |t|
    t.text "name"
    t.text "cidr_block"
    t.text "driver_id"
    t.bigint "scenario_id", null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.bigint "status", default: 0
    t.text "log", default: ""
    t.text "boot_code", default: ""
    t.index ["scenario_id"], name: "index_clouds_on_scenario_id"
  end

  create_table "groups", force: :cascade do |t|
    t.text "name"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.bigint "scenario_id", null: false
    t.text "instructions", default: ""
  end

  create_table "instance_groups", force: :cascade do |t|
    t.bigint "group_id", null: false
    t.bigint "instance_id", null: false
    t.boolean "administrator"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean "ip_visible", default: true
    t.index ["group_id"], name: "index_instance_groups_on_group_id"
    t.index ["instance_id"], name: "index_instance_groups_on_instance_id"
  end

  create_table "instance_roles", force: :cascade do |t|
    t.bigint "instance_id", null: false
    t.bigint "role_id", null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["instance_id"], name: "index_instance_roles_on_instance_id"
    t.index ["role_id"], name: "index_instance_roles_on_role_id"
  end

  create_table "instances", force: :cascade do |t|
    t.text "name"
    t.text "ip_address"
    t.text "driver_id"
    t.text "os"
    t.boolean "internet_accessible"
    t.bigint "subnet_id", null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.bigint "status", default: 0
    t.text "scoring_url"
    t.text "scoring_page"
    t.text "uuid"
    t.text "log", default: ""
    t.text "ip_address_dynamic", default: ""
    t.text "boot_code", default: ""
    t.text "ip_address_public"
    t.index ["subnet_id"], name: "index_instances_on_subnet_id"
  end

  create_table "players", force: :cascade do |t|
    t.text "login"
    t.text "password"
    t.bigint "group_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.bigint "user_id"
    t.bigint "student_group_id"
    t.index ["group_id"], name: "index_players_on_group_id"
  end

  create_table "questions", force: :cascade do |t|
    t.bigint "scenario_id", null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.bigint "order"
    t.text "text"
    t.text "type_of"
    t.text "options"
    t.text "values"
    t.bigint "points"
    t.bigint "points_penalty"
    t.index ["scenario_id"], name: "index_questions_on_scenario_id"
  end

  create_table "recipes", force: :cascade do |t|
    t.bigint "scenario_id", null: false
    t.text "name"
    t.boolean "custom"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "role_recipes", force: :cascade do |t|
    t.bigint "role_id"
    t.bigint "recipe_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["recipe_id"], name: "index_role_recipes_on_recipe_id"
    t.index ["role_id"], name: "index_role_recipes_on_role_id"
  end

  create_table "roles", force: :cascade do |t|
    t.text "name"
    t.text "packages"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.bigint "scenario_id"
  end

  create_table "scenarios", force: :cascade do |t|
    t.text "name"
    t.text "description"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.bigint "status", default: 0
    t.text "log", default: ""
    t.text "answers", default: ""
    t.text "uuid"
    t.text "scoring_pages"
    t.text "answers_url"
    t.text "scoring_pages_content", default: ""
    t.bigint "user_id"
    t.text "com_page"
    t.boolean "modified", default: false
    t.text "instructions", default: ""
    t.text "instructions_student", default: ""
    t.bigint "location", default: 0
    t.boolean "modifiable", default: false
    t.text "boot_code", default: ""
    t.boolean "archived", default: false, null: false
    t.string "secret"
  end

  create_table "schedules", force: :cascade do |t|
    t.bigint "user_id"
    t.text "scenario"
    t.text "scenario_location"
    t.text "uuid"
    t.datetime "start_time"
    t.datetime "end_time"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "statistics", force: :cascade do |t|
    t.bigint "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "bash_histories", default: ""
    t.text "bash_analytics"
    t.text "scenario_name"
    t.datetime "scenario_created_at"
    t.text "script_log", default: ""
    t.text "exit_status", default: ""
    t.bigint "scenario_id"
    t.text "resource_info"
  end

  create_table "student_group_users", force: :cascade do |t|
    t.bigint "student_group_id"
    t.bigint "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "student_groups", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.text "name", default: "", null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text "registration_code"
  end

  create_table "subnets", force: :cascade do |t|
    t.text "name"
    t.text "cidr_block"
    t.text "driver_id"
    t.boolean "internet_accessible", default: false
    t.bigint "cloud_id", null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.bigint "status", default: 0
    t.text "log", default: ""
    t.text "boot_code", default: ""
    t.index ["cloud_id"], name: "index_subnets_on_cloud_id"
  end

  create_table "tutorials", force: :cascade do |t|
    t.text "title"
    t.text "text"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "users", force: :cascade do |t|
    t.text "email", default: "", null: false
    t.text "encrypted_password", default: "", null: false
    t.text "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.bigint "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.text "current_sign_in_ip"
    t.text "last_sign_in_ip"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text "name", null: false
    t.bigint "role"
    t.text "organization"
    t.text "registration_code"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  create_table "variable_templates", id: :serial, force: :cascade do |t|
    t.integer "group_id"
    t.integer "scenario_id"
    t.string "name", null: false
    t.string "type", null: false
    t.string "value"
    t.index ["group_id", "name"], name: "index_variable_templates_on_group_id_and_name", unique: true
    t.index ["scenario_id", "name"], name: "index_variable_templates_on_scenario_id_and_name", unique: true
  end

  create_table "variables", id: :serial, force: :cascade do |t|
    t.integer "variable_template_id", null: false
    t.integer "player_id"
    t.integer "scenario_id"
    t.string "value", null: false
    t.index ["variable_template_id", "player_id"], name: "index_variables_on_variable_template_id_and_player_id", unique: true
    t.index ["variable_template_id", "scenario_id"], name: "index_variables_on_variable_template_id_and_scenario_id", unique: true
  end

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
