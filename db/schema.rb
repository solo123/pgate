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

ActiveRecord::Schema.define(version: 20161012071542) do

  create_table "app_configs", force: :cascade do |t|
    t.string   "group"
    t.string   "name"
    t.string   "val"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "biz_errors", force: :cascade do |t|
    t.string   "error_source_type"
    t.integer  "error_source_id"
    t.string   "code"
    t.string   "message"
    t.text     "detail"
    t.datetime "created_at",        null: false
    t.datetime "updated_at",        null: false
    t.index ["error_source_type", "error_source_id"], name: "index_biz_errors_on_error_source_type_and_error_source_id"
  end

  create_table "client_payments", force: :cascade do |t|
    t.integer  "client_id"
    t.string   "org_id"
    t.string   "trans_type"
    t.string   "order_time"
    t.string   "order_id"
    t.string   "order_title"
    t.string   "pay_pass"
    t.string   "img_url"
    t.integer  "amount"
    t.integer  "fee"
    t.string   "card_no"
    t.string   "card_holder_name"
    t.string   "person_id_num"
    t.string   "notify_url"
    t.string   "callback_url"
    t.string   "mac"
    t.datetime "finish_time"
    t.integer  "status",           default: 0
    t.datetime "created_at",                   null: false
    t.datetime "updated_at",                   null: false
    t.string   "resp_code"
    t.string   "resp_desc"
    t.string   "redirect_url"
    t.string   "pay_code"
    t.string   "pay_desc"
    t.string   "t0_code"
    t.string   "t0_desc"
    t.string   "remote_ip"
    t.string   "uni_order_id"
    t.index ["client_id"], name: "index_client_payments_on_client_id"
    t.index ["order_id"], name: "index_client_payments_on_order_id"
    t.index ["org_id"], name: "index_client_payments_on_org_id"
  end

  create_table "clients", force: :cascade do |t|
    t.string   "name"
    t.string   "org_id"
    t.string   "tmk"
    t.integer  "d0_min_fee"
    t.integer  "d0_min_percent"
    t.integer  "status"
    t.datetime "created_at",     null: false
    t.datetime "updated_at",     null: false
  end

  create_table "kaifu_gateways", force: :cascade do |t|
    t.integer  "client_payment_id"
    t.string   "send_time"
    t.string   "send_seq_id"
    t.string   "trans_type"
    t.string   "organization_id"
    t.string   "pay_pass"
    t.string   "img_url"
    t.string   "trans_amt"
    t.string   "fee"
    t.string   "card_no"
    t.string   "name"
    t.string   "id_num"
    t.string   "body"
    t.string   "notify_url"
    t.string   "callback_url"
    t.string   "resp_code"
    t.string   "resp_desc"
    t.string   "mac"
    t.datetime "finish_time"
    t.integer  "status",            default: 0
    t.datetime "created_at",                    null: false
    t.datetime "updated_at",                    null: false
    t.string   "redirect_url"
    t.string   "response_text"
    t.string   "pay_code"
    t.string   "pay_desc"
    t.string   "t0_code"
    t.string   "t0_desc"
    t.index ["client_payment_id"], name: "index_kaifu_gateways_on_client_payment_id"
    t.index ["organization_id"], name: "index_kaifu_gateways_on_organization_id"
    t.index ["send_seq_id"], name: "index_kaifu_gateways_on_send_seq_id"
  end

  create_table "kaifu_queries", force: :cascade do |t|
    t.integer  "payment_query_id"
    t.string   "send_time"
    t.string   "send_seq_id"
    t.string   "trans_type"
    t.string   "organization_id"
    t.string   "org_send_seq_id"
    t.string   "trans_time"
    t.string   "pay_result"
    t.string   "pay_desc"
    t.string   "t0_pay_result"
    t.string   "t0_pay_desc"
    t.string   "resp_code"
    t.string   "resp_desc"
    t.string   "mac"
    t.string   "response_text"
    t.datetime "created_at",       null: false
    t.datetime "updated_at",       null: false
    t.index ["payment_query_id"], name: "index_kaifu_queries_on_payment_query_id"
  end

  create_table "kaifu_results", force: :cascade do |t|
    t.integer  "client_id"
    t.integer  "client_payment_id"
    t.string   "send_time"
    t.string   "send_seq_id"
    t.string   "organization_id"
    t.string   "org_send_seq_id"
    t.integer  "trans_amt"
    t.integer  "fee"
    t.string   "pay_result"
    t.string   "pay_desc"
    t.string   "t0_resp_code"
    t.string   "t0_resp_desc"
    t.string   "resp_code"
    t.string   "resp_desc"
    t.string   "mac"
    t.string   "notify_url"
    t.integer  "notify_status",     default: 0
    t.datetime "notify_time"
    t.integer  "status",            default: 0
    t.datetime "created_at",                    null: false
    t.datetime "updated_at",                    null: false
    t.integer  "kaifu_gateway_id"
    t.string   "sender_type"
    t.integer  "sender_id"
    t.index ["client_id"], name: "index_kaifu_results_on_client_id"
    t.index ["client_payment_id"], name: "index_kaifu_results_on_client_payment_id"
    t.index ["sender_type", "sender_id"], name: "index_kaifu_results_on_sender_type_and_sender_id"
  end

  create_table "kaifu_signins", force: :cascade do |t|
    t.string   "send_time"
    t.string   "send_seq_id"
    t.string   "trans_type"
    t.string   "organization_id"
    t.string   "terminal_info"
    t.string   "resp_code"
    t.string   "resp_desc"
    t.integer  "status",          default: 0
    t.datetime "created_at",                  null: false
    t.datetime "updated_at",                  null: false
  end

  create_table "notifies", force: :cascade do |t|
    t.string   "sender_type"
    t.integer  "sender_id"
    t.string   "data"
    t.string   "notify_url"
    t.text     "message"
    t.integer  "status",      default: 0
    t.datetime "created_at",              null: false
    t.datetime "updated_at",              null: false
    t.index ["sender_type", "sender_id"], name: "index_notifies_on_sender_type_and_sender_id"
  end

  create_table "payment_queries", force: :cascade do |t|
    t.integer  "client_id"
    t.string   "org_id"
    t.string   "query_type"
    t.string   "order_time"
    t.string   "order_id"
    t.string   "pay_code"
    t.string   "pay_desc"
    t.string   "resp_code"
    t.string   "resp_desc"
    t.string   "mac"
    t.datetime "created_at",        null: false
    t.datetime "updated_at",        null: false
    t.integer  "client_payment_id"
    t.string   "t0_code"
    t.string   "t0_desc"
    t.index ["client_id"], name: "index_payment_queries_on_client_id"
  end

  create_table "post_dats", force: :cascade do |t|
    t.string   "sender_type"
    t.integer  "sender_id"
    t.string   "url"
    t.string   "data"
    t.string   "response"
    t.string   "body"
    t.text     "error_message"
    t.datetime "created_at",    null: false
    t.datetime "updated_at",    null: false
    t.index ["sender_type", "sender_id"], name: "index_post_dats_on_sender_type_and_sender_id"
  end

  create_table "recv1_posts", force: :cascade do |t|
    t.string   "method"
    t.string   "remote_host"
    t.string   "header"
    t.string   "params"
    t.text     "detail"
    t.integer  "status",      default: 0
    t.datetime "created_at",              null: false
    t.datetime "updated_at",              null: false
  end

  create_table "recv_posts", force: :cascade do |t|
    t.string   "method"
    t.string   "remote_host"
    t.string   "header"
    t.string   "params"
    t.text     "detail"
    t.integer  "status",      default: 0
    t.datetime "created_at",              null: false
    t.datetime "updated_at",              null: false
    t.string   "data"
    t.string   "message"
  end

  create_table "tfb_orders", force: :cascade do |t|
    t.integer  "client_payment_id"
    t.string   "sign_type"
    t.string   "ver"
    t.string   "input_charset"
    t.string   "sign"
    t.integer  "sign_key_index"
    t.string   "spid"
    t.string   "notify_url"
    t.string   "pay_show_url"
    t.string   "sp_billno"
    t.string   "spbill_create_ip"
    t.string   "pay_type"
    t.string   "tran_time"
    t.integer  "tran_amt"
    t.string   "cur_type"
    t.string   "pay_limit"
    t.string   "auth_code"
    t.string   "item_name"
    t.string   "item_attach"
    t.string   "attach"
    t.string   "sp_udid"
    t.string   "bank_mch_name"
    t.string   "bank_mch_id"
    t.string   "retcode"
    t.string   "retmsg"
    t.string   "listid"
    t.string   "qrcode"
    t.string   "pay_info"
    t.string   "sysd_time"
    t.integer  "status",            default: 0
    t.datetime "created_at",                    null: false
    t.datetime "updated_at",                    null: false
    t.index ["client_payment_id"], name: "index_tfb_orders_on_client_payment_id"
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
