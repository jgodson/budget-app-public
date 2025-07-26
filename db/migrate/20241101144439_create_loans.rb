class CreateLoans < ActiveRecord::Migration[7.1]
  def change
    create_table :loans do |t|
      t.string :loan_name, null: false                           # Name of the loan
      t.integer :balance, null: false                            # Current balance of the loan
      t.references :category, foreign_key: true                  # links to Category

      t.timestamps
    end
  end
end
