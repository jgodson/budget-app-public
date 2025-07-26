class CreateTransactions < ActiveRecord::Migration[7.1]
  def change
    create_table :transactions do |t|
      t.date :date, null: false                                      # date of the transaction
      t.string :description                                          # optional description
      t.integer :amount, null: false                                 # amount in cents
      t.references :category, foreign_key: true                      # links to Category
      t.timestamps
    end    
  end
end
