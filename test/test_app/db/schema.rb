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

ActiveRecord::Schema[7.1].define(version: 2024_07_03_016003) do
  create_table "ar_big_table_values", force: :cascade do |t|
    t.integer "ar_big_table_id"
    t.string "value"
    t.string "description"
    t.string "locales"
    t.boolean "active", default: true
    t.integer "created_by"
    t.integer "updated_by"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["ar_big_table_id"], name: "bt_by_ar_big_table_id"
  end

  create_table "ar_big_tables", force: :cascade do |t|
    t.string "key"
    t.string "description"
    t.integer "site_id"
    t.boolean "active", default: true
    t.integer "created_by"
    t.integer "updated_by"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["key", "site_id"], name: "index_ar_big_tables_on_key_and_site_id"
  end

  create_table "ar_categories", force: :cascade do |t|
    t.string "name"
    t.string "description"
    t.integer "ctype", default: 1
    t.integer "parent"
    t.boolean "active", default: true
    t.integer "order", default: 0
    t.integer "created_by"
    t.integer "updated_by"
    t.integer "ar_site_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["ar_site_id"], name: "index_ar_categories_on_ar_site_id"
    t.index ["ctype"], name: "index_ar_categories_on_ctype"
    t.index ["name"], name: "index_ar_categories_on_name"
  end

  create_table "ar_designs", force: :cascade do |t|
    t.string "description", default: ""
    t.string "body", default: ""
    t.string "css", default: ""
    t.string "rails_view", default: ""
    t.string "params", default: ""
    t.string "code", default: ""
    t.string "author"
    t.integer "site_id"
    t.integer "created_by"
    t.integer "updated_by"
    t.boolean "active", default: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "ar_filters", force: :cascade do |t|
    t.integer "ar_user_id"
    t.string "table"
    t.string "description"
    t.string "filter", default: ""
    t.boolean "public"
    t.boolean "active", default: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["table", "ar_user_id"], name: "index_ar_filters_on_table_and_ar_user_id"
  end

  create_table "ar_folder_permissions", force: :cascade do |t|
    t.string "folder_name"
    t.boolean "inherited", default: true
    t.boolean "active", default: true
    t.integer "created_by"
    t.integer "updated_by"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["folder_name"], name: "index_ar_folder_permissions_on_folder_name", unique: true
  end

  create_table "ar_folder_rules", force: :cascade do |t|
    t.integer "ar_folder_permission_id"
    t.integer "ar_role_id"
    t.integer "permission", default: 0
    t.boolean "active", default: true
    t.integer "created_by"
    t.integer "updated_by"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["ar_folder_permission_id"], name: "index_ar_folder_rules_on_ar_folder_permission_id"
    t.index ["ar_role_id"], name: "index_ar_folder_rules_on_ar_role_id"
  end

  create_table "ar_galleries", force: :cascade do |t|
    t.string "title"
    t.string "description"
    t.string "picture"
    t.string "thumbnail"
    t.integer "doc_id"
    t.string "doc_type"
    t.integer "order", default: 10
    t.boolean "active", default: true
    t.integer "created_by"
    t.integer "updated_by"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["doc_type", "doc_id"], name: "index_ar_galleries_on_doc_type_and_doc_id"
  end

  create_table "ar_journals", force: :cascade do |t|
    t.integer "user_id"
    t.integer "site_id"
    t.integer "record_id"
    t.string "operation"
    t.string "tables"
    t.string "ids"
    t.string "ip"
    t.datetime "time"
    t.string "diff"
    t.index ["tables", "record_id"], name: "index_ar_journals_on_tables_and_record_id"
    t.index ["user_id"], name: "index_ar_journals_on_user_id"
  end

  create_table "ar_key_value_stores", force: :cascade do |t|
    t.string "key"
    t.string "value"
    t.index ["key"], name: "index_ar_key_value_stores_on_key", unique: true
  end

  create_table "ar_links", force: :cascade do |t|
    t.string "link"
    t.string "params"
    t.boolean "active", default: true
    t.string "redirect"
    t.integer "page_id"
    t.integer "ar_site_id"
    t.integer "created_by"
    t.integer "updated_by"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["ar_site_id", "link"], name: "index_ar_links_on_ar_site_id_and_link", unique: true
  end

  create_table "ar_memories", force: :cascade do |t|
    t.string "data"
  end

  create_table "ar_menu_items", force: :cascade do |t|
    t.string "caption"
    t.string "link"
    t.string "picture"
    t.integer "page_id"
    t.text "content"
    t.string "clas"
    t.string "link_to"
    t.string "target"
    t.integer "order", default: 0
    t.boolean "active", default: true
    t.boolean "hidden", default: false
    t.boolean "prepend_path", default: true
    t.integer "policy_id"
    t.integer "parent_id", default: 0
    t.integer "created_by"
    t.integer "updated_by"
    t.integer "ar_menu_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["ar_menu_id"], name: "index_ar_menu_items_on_ar_menu_id"
  end

  create_table "ar_menus", force: :cascade do |t|
    t.string "name"
    t.string "description"
    t.string "div_name"
    t.boolean "link_name"
    t.string "css"
    t.boolean "active", default: true
    t.integer "ar_site_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "created_by"
    t.integer "updated_by"
    t.index ["ar_site_id"], name: "index_ar_menus_on_ar_site_id"
    t.index ["name"], name: "index_ar_menus_on_name", unique: true
  end

  create_table "ar_pages", force: :cascade do |t|
    t.string "subject", default: ""
    t.string "link", default: ""
    t.string "alt_link", default: ""
    t.string "sub_subject", default: ""
    t.string "picture"
    t.boolean "gallery"
    t.string "body", default: ""
    t.string "css", default: ""
    t.string "script", default: ""
    t.string "params"
    t.string "div_class"
    t.string "menu_id"
    t.integer "author_id"
    t.string "author_name"
    t.integer "ar_poll_id"
    t.datetime "publish_date"
    t.string "user_name"
    t.datetime "valid_from"
    t.datetime "valid_to"
    t.boolean "comments", default: true
    t.boolean "active", default: true
    t.string "if_url"
    t.integer "if_border", default: 0
    t.integer "if_width"
    t.integer "if_height"
    t.string "if_scroll"
    t.string "if_id"
    t.string "if_class"
    t.string "if_params"
    t.string "title"
    t.string "meta_description"
    t.string "canonical_link"
    t.integer "policy_id"
    t.integer "ar_site_id"
    t.integer "ar_design_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "created_by"
    t.integer "updated_by"
    t.index ["alt_link"], name: "index_ar_pages_on_alt_link"
    t.index ["ar_site_id"], name: "index_ar_pages_on_ar_site_id"
    t.index ["link"], name: "index_ar_pages_on_link"
  end

  create_table "ar_parts", force: :cascade do |t|
    t.string "name", default: ""
    t.string "link"
    t.string "description", default: ""
    t.string "picture"
    t.string "thumbnail"
    t.string "body", default: ""
    t.string "css", default: ""
    t.string "script", default: ""
    t.string "script_type", default: ""
    t.string "params", default: ""
    t.string "div_id"
    t.integer "site_id"
    t.integer "order", default: 0
    t.boolean "active", default: true
    t.datetime "valid_from"
    t.datetime "valid_to"
    t.integer "policy_id"
    t.integer "parent_id"
    t.string "parent_type"
    t.integer "created_by"
    t.integer "updated_by"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["parent_type", "parent_id"], name: "ar_part_by_parent"
  end

  create_table "ar_permission_rules", force: :cascade do |t|
    t.integer "ar_permission_id"
    t.integer "ar_role_id"
    t.integer "permission", default: 0
    t.boolean "active", default: true
    t.integer "created_by"
    t.integer "updated_by"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["ar_permission_id"], name: "index_ar_permission_rules_on_ar_permission_id"
  end

  create_table "ar_permissions", force: :cascade do |t|
    t.string "table_name"
    t.boolean "is_default"
    t.boolean "active", default: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "created_by"
    t.integer "updated_by"
    t.index ["table_name"], name: "index_ar_permissions_on_table_name", unique: true
  end

  create_table "ar_pieces", force: :cascade do |t|
    t.string "name", default: ""
    t.string "link"
    t.string "description", default: ""
    t.string "picture"
    t.string "thumbnail"
    t.string "body", default: ""
    t.string "css", default: ""
    t.string "script", default: ""
    t.string "script_type", default: ""
    t.string "params", default: ""
    t.string "div_id"
    t.integer "site_id"
    t.integer "order", default: 0
    t.boolean "active", default: true
    t.datetime "valid_from"
    t.datetime "valid_to"
    t.integer "policy_id"
    t.integer "created_by"
    t.integer "updated_by"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "ar_policies", force: :cascade do |t|
    t.string "name"
    t.string "description", default: ""
    t.boolean "is_default", default: false
    t.boolean "active", default: true
    t.string "message", default: ""
    t.string "rules", default: ""
    t.integer "ar_site_id"
    t.integer "created_by"
    t.integer "updated_by"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["ar_site_id"], name: "index_ar_policies_on_ar_site_id"
  end

  create_table "ar_policy_rules", force: :cascade do |t|
    t.integer "ar_role_id"
    t.integer "permission", default: 0
    t.boolean "active", default: true
    t.integer "ar_policy_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "created_by"
    t.integer "updated_by"
    t.index ["ar_policy_id"], name: "index_ar_policy_rules_on_ar_policy_id"
  end

  create_table "ar_poll_items", force: :cascade do |t|
    t.string "name", default: ""
    t.string "text", default: ""
    t.string "field_type", default: ""
    t.string "size", default: "10"
    t.boolean "mandatory", default: false
    t.string "separator", default: ""
    t.string "options", default: ""
    t.integer "order", default: 0
    t.integer "ar_poll_id"
    t.boolean "active", default: true
    t.integer "created_by"
    t.integer "updated_by"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["ar_poll_id"], name: "index_ar_poll_items_on_ar_poll_id"
  end

  create_table "ar_poll_results", force: :cascade do |t|
    t.integer "ar_poll_id"
    t.string "data"
    t.boolean "confirmed"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["ar_poll_id"], name: "index_ar_poll_results_on_ar_poll_id"
  end

  create_table "ar_polls", force: :cascade do |t|
    t.string "name", default: ""
    t.string "title", default: ""
    t.string "sub_text", default: ""
    t.string "pre_display"
    t.string "operation"
    t.string "parameters"
    t.string "display", default: "1"
    t.string "css"
    t.string "js"
    t.string "form"
    t.datetime "valid_from"
    t.datetime "valid_to"
    t.string "captcha_type"
    t.boolean "active", default: true
    t.integer "created_by"
    t.integer "updated_by"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_ar_polls_on_name", unique: true
  end

  create_table "ar_removed_urls", force: :cascade do |t|
    t.string "url"
    t.string "description"
    t.integer "created_by"
    t.integer "updated_by"
    t.integer "ar_site_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["ar_site_id"], name: "index_ar_removed_urls_on_ar_site_id"
  end

  create_table "ar_roles", force: :cascade do |t|
    t.string "name"
    t.string "system_name"
    t.boolean "active", default: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "created_by"
    t.integer "updated_by"
    t.index ["name"], name: "index_ar_roles_on_name", unique: true
    t.index ["system_name"], name: "index_ar_roles_on_system_name"
  end

  create_table "ar_setups", force: :cascade do |t|
    t.string "name"
    t.text "data"
    t.text "form"
    t.string "edit_ids"
    t.integer "created_by"
    t.integer "updated_by"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_ar_setups_on_name"
  end

  create_table "ar_sites", force: :cascade do |t|
    t.string "name"
    t.string "description"
    t.string "homepage_link"
    t.string "error_link"
    t.string "header"
    t.string "css"
    t.string "route_name"
    t.string "page_title"
    t.string "page_class", default: "ArPage"
    t.string "site_layout", default: "content"
    t.string "menu_class", default: "ArMenu"
    t.string "request_processor"
    t.string "files_directory"
    t.string "logo"
    t.string "favicon"
    t.string "menu_name"
    t.integer "menu_id"
    t.string "settings"
    t.string "alias_for"
    t.string "rails_view"
    t.string "design"
    t.integer "inherit_policy"
    t.boolean "active", default: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "created_by"
    t.integer "updated_by"
    t.index ["alias_for"], name: "index_ar_sites_on_alias_for"
    t.index ["name"], name: "index_ar_sites_on_name", unique: true
  end

  create_table "ar_temps", force: :cascade do |t|
    t.string "key"
    t.boolean "active"
    t.string "data"
    t.string "order"
  end

  create_table "ar_user_groups", force: :cascade do |t|
    t.integer "ar_user_id"
    t.integer "group_id"
    t.index ["ar_user_id"], name: "index_ar_user_groups_on_ar_user_id"
    t.index ["group_id"], name: "index_ar_user_groups_on_group_id"
  end

  create_table "ar_user_roles", force: :cascade do |t|
    t.integer "ar_role_id"
    t.integer "ar_user_id"
    t.date "valid_from"
    t.date "valid_to"
    t.boolean "active", default: true
    t.integer "created_by"
    t.integer "updated_by"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["ar_role_id", "ar_user_id"], name: "index_ar_user_roles_2"
    t.index ["ar_user_id", "ar_role_id"], name: "index_ar_user_roles_1"
  end

  create_table "ar_users", force: :cascade do |t|
    t.string "username", default: ""
    t.string "title", default: ""
    t.string "first_name", default: ""
    t.string "middle_name", default: ""
    t.string "last_name", default: ""
    t.string "name"
    t.string "company", default: ""
    t.string "address"
    t.string "post"
    t.string "country"
    t.string "phone"
    t.string "email"
    t.string "www"
    t.string "picture"
    t.date "birthdate"
    t.string "about"
    t.datetime "last_visit"
    t.boolean "active", default: true
    t.date "valid_from"
    t.date "valid_to"
    t.boolean "group", default: false
    t.string "signature"
    t.string "interests"
    t.string "job_occup"
    t.string "description"
    t.date "reg_date"
    t.string "password_digest"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "created_by"
    t.integer "updated_by"
    t.index ["email"], name: "index_ar_users_on_email", unique: true
    t.index ["group"], name: "index_ar_users_on_group"
    t.index ["username"], name: "index_ar_users_on_username", unique: true
  end

  create_table "ar_visits", force: :cascade do |t|
    t.integer "page_id"
    t.integer "user_id"
    t.integer "site_id"
    t.string "session_id"
    t.string "ip"
    t.datetime "time"
    t.index ["time"], name: "index_ar_visits_on_time"
  end

  create_table "diaries", force: :cascade do |t|
    t.string "title"
    t.string "body"
    t.datetime "time_begin"
    t.integer "duration"
    t.string "search"
    t.boolean "closed", default: true
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_diaries_on_user_id"
  end

  create_table "sessions", force: :cascade do |t|
    t.string "session_id", null: false
    t.text "data"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["session_id"], name: "index_sessions_on_session_id", unique: true
    t.index ["updated_at"], name: "index_sessions_on_updated_at"
  end

  create_table "todos", force: :cascade do |t|
    t.integer "ar_user_id"
    t.string "subject"
    t.string "body"
    t.datetime "time"
    t.integer "priority", default: 1
    t.boolean "closed"
    t.datetime "time_closed"
    t.integer "created_by"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["ar_user_id"], name: "index_todos_on_ar_user_id"
  end

end
