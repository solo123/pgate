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

ActiveRecord::Schema.define(version: 20161025153306) do

  create_table "app_configs", force: :cascade do |t|
    t.string   "group"
    t.string   "name"
    t.string   "val"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "cards", force: :cascade do |t|
    t.string   "card_num"
    t.string   "holder_name"
    t.string   "person_id_num"
    t.datetime "created_at",    null: false
    t.datetime "updated_at",    null: false
  end

  create_table "http_logs", force: :cascade do |t|
    t.string   "sender_type"
    t.integer  "sender_id"
    t.string   "method"
    t.string   "sender"
    t.string   "receiver"
    t.text     "remote_detail"
    t.text     "send_data"
    t.text     "resp_body"
    t.datetime "created_at",    null: false
    t.datetime "updated_at",    null: false
    t.index ["sender_type", "sender_id"], name: "index_http_logs_on_sender_type_and_sender_id"
  end

  create_table "notify_recvs", force: :cascade do |t|
    t.string   "method"
    t.string   "sender"
    t.string   "send_host"
    t.text     "params"
    t.text     "data"
    t.text     "result_message"
    t.integer  "status",         default: 0
    t.datetime "created_at",                 null: false
    t.datetime "updated_at",                 null: false
  end

  create_table "orgs", force: :cascade do |t|
    t.string   "name"
    t.string   "org_code"
    t.string   "tmk"
    t.integer  "d0_rate"
    t.integer  "d0_min_fee"
    t.integer  "t1_rate"
    t.integer  "status",     default: 0
    t.datetime "created_at",             null: false
    t.datetime "updated_at",             null: false
  end

  create_table "pay_results", force: :cascade do |t|
    t.integer  "payment_id"
    t.string   "channel_name"
    t.string   "uni_order_num"
    t.string   "channel_order_num"
    t.string   "real_order_num"
    t.string   "send_code"
    t.string   "send_desc"
    t.datetime "send_time"
    t.string   "pay_code"
    t.string   "pay_desc"
    t.datetime "pay_time"
    t.string   "t0_code"
    t.string   "t0_desc"
    t.string   "pay_url"
    t.string   "barcode_url"
    t.datetime "created_at",        null: false
    t.datetime "updated_at",        null: false
    t.index ["payment_id"], name: "index_pay_results_on_payment_id"
  end

  create_table "payments", force: :cascade do |t|
    t.integer  "req_recv_id"
    t.string   "app_id"
    t.string   "open_id"
    t.integer  "org_id"
    t.string   "order_num"
    t.string   "order_day"
    t.string   "order_time"
    t.string   "order_expire_time"
    t.string   "goods_tag"
    t.string   "product_id"
    t.string   "order_title"
    t.string   "attach_info"
    t.integer  "amount"
    t.integer  "fee"
    t.string   "limit_pay"
    t.string   "remote_ip"
    t.string   "terminal_num"
    t.string   "method"
    t.string   "callback_url"
    t.string   "notify_url"
    t.integer  "card_id"
    t.integer  "status",            default: 0
    t.datetime "created_at",                    null: false
    t.datetime "updated_at",                    null: false
    t.index ["card_id"], name: "index_payments_on_card_id"
    t.index ["order_day"], name: "index_payments_on_order_day"
    t.index ["order_num"], name: "index_payments_on_order_num"
    t.index ["org_id"], name: "index_payments_on_org_id"
    t.index ["req_recv_id"], name: "index_payments_on_req_recv_id"
  end

  create_table "req_recvs", force: :cascade do |t|
    t.string   "remote_ip"
    t.string   "method"
    t.string   "org_code"
    t.string   "sign"
    t.text     "data"
    t.text     "params"
    t.datetime "time_recv"
    t.text     "resp_body"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "sent_posts", force: :cascade do |t|
    t.string   "sender_type"
    t.integer  "sender_id"
    t.string   "method"
    t.string   "post_url"
    t.text     "post_data"
    t.string   "resp_type"
    t.text     "resp_body"
    t.text     "result_message"
    t.datetime "created_at",     null: false
    t.datetime "updated_at",     null: false
    t.index ["sender_type", "sender_id"], name: "index_sent_posts_on_sender_type_and_sender_id"
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
    t.datetime "created_at",                          null: false
    t.datetime "updated_at",                          null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

end
