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

ActiveRecord::Schema[8.1].define(version: 2026_05_12_230124) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "companies", force: :cascade do |t|
    t.boolean "archived", default: false
    t.string "city"
    t.string "company_name"
    t.string "country"
    t.datetime "created_at", null: false
    t.string "dic"
    t.string "first_name"
    t.string "ic_dph"
    t.string "ico"
    t.string "last_name"
    t.string "street"
    t.string "type"
    t.datetime "updated_at", null: false
    t.integer "user_id"
    t.string "zip"
  end

  create_table "invoice_items", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "description"
    t.integer "invoice_id"
    t.decimal "quantity"
    t.decimal "tax_rate"
    t.decimal "total_with_vat"
    t.decimal "total_without_vat"
    t.decimal "unit_price"
    t.datetime "updated_at", null: false
    t.decimal "vat_amount"
  end

  create_table "invoices", force: :cascade do |t|
    t.boolean "art", default: false
    t.boolean "collectibles", default: false
    t.datetime "created_at", null: false
    t.string "currency"
    t.integer "customer_id"
    t.date "delivery_date"
    t.string "invoice_number"
    t.boolean "is_cancelled", default: false
    t.date "issue_date"
    t.integer "parent_id"
    t.boolean "reverse_charge", default: false
    t.boolean "self_billed", default: false
    t.integer "supplier_id"
    t.decimal "total_vat_amount"
    t.decimal "total_with_vat"
    t.decimal "total_without_vat"
    t.boolean "travelling_agency", default: false
    t.datetime "updated_at", null: false
    t.boolean "used_item", default: false
    t.integer "user_id"
    t.boolean "vat_exempt", default: false
    t.integer "version", default: 1
  end

  create_table "receipt_items", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "description"
    t.decimal "quantity"
    t.integer "receipt_id"
    t.decimal "total_price"
    t.decimal "unit_price"
    t.datetime "updated_at", null: false
  end

  create_table "receipts", force: :cascade do |t|
    t.string "cash_register_code"
    t.datetime "created_at", null: false
    t.string "dic"
    t.string "ic_dph"
    t.string "ico"
    t.datetime "issued_at"
    t.string "merchant_address"
    t.string "merchant_name"
    t.string "receipt_number"
    t.decimal "total_amount"
    t.datetime "updated_at", null: false
    t.integer "user_id"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email"
    t.string "first_name"
    t.string "last_name"
    t.string "password_digest"
    t.datetime "updated_at", null: false
  end
end
