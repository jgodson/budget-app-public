class CreateBudgets < ActiveRecord::Migration[7.1]
  def change
    create_table :budgets do |t|
      t.references :category, null: false, foreign_key: true
      t.integer :year, null: false
      t.integer :month, null: true # Null month means the budget applies to the whole year
      t.integer :budgeted_amount, null: false

      t.timestamps
    end

    # Ensure there are no duplicate budget entries for the same category, year, and month
    add_index :budgets, [:category_id, :year, :month], unique: true
  end
end
