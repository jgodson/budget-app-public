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

ActiveRecord::Schema[7.1].define(version: 2026_02_04_120000) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "budgets", force: :cascade do |t|
    t.bigint "category_id", null: false
    t.integer "year", null: false
    t.integer "month"
    t.integer "budgeted_amount", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["category_id", "year", "month"], name: "index_budgets_on_category_id_and_year_and_month", unique: true
    t.index ["category_id"], name: "index_budgets_on_category_id"
  end

  create_table "categories", force: :cascade do |t|
    t.string "name", null: false
    t.integer "category_type", null: false
    t.bigint "parent_category_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name", "parent_category_id"], name: "index_categories_on_name_and_parent_category_id", unique: true
    t.index ["parent_category_id"], name: "index_categories_on_parent_category_id"
  end

  create_table "goals", force: :cascade do |t|
    t.string "goal_name", null: false
    t.integer "amount", null: false
    t.bigint "category_id", null: false
    t.datetime "archived_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["category_id"], name: "index_goals_on_category_id", unique: true
  end

  create_table "loan_payments", force: :cascade do |t|
    t.bigint "loan_id", null: false
    t.integer "paid_amount", null: false
    t.integer "interest_amount", null: false
    t.date "payment_date", null: false
    t.bigint "associated_transaction_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["associated_transaction_id"], name: "index_loan_payments_on_associated_transaction_id"
    t.index ["loan_id"], name: "index_loan_payments_on_loan_id"
  end

  create_table "loans", force: :cascade do |t|
    t.string "loan_name", null: false
    t.integer "balance", null: false
    t.bigint "category_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.decimal "apr", precision: 5, scale: 2
    t.index ["category_id"], name: "index_loans_on_category_id"
  end

  create_table "transactions", force: :cascade do |t|
    t.date "date", null: false
    t.string "description"
    t.integer "amount", null: false
    t.bigint "category_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "import_source", default: "Existing", null: false
    t.index ["category_id"], name: "index_transactions_on_category_id"
  end

  add_foreign_key "budgets", "categories"
  add_foreign_key "categories", "categories", column: "parent_category_id"
  add_foreign_key "goals", "categories"
  add_foreign_key "loan_payments", "loans"
  add_foreign_key "loan_payments", "transactions", column: "associated_transaction_id"
  add_foreign_key "loans", "categories"
  add_foreign_key "transactions", "categories"
end
