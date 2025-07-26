class CreateLoanPayments < ActiveRecord::Migration[7.1]
  def change
    create_table :loan_payments do |t|
      t.references :loan, null: false, foreign_key: true         # Reference to the loan
      t.integer :paid_amount, null: false                        # Amount paid
      t.integer :interest_amount, null: false                    # Amount of the payment that goes to interest
      t.date :payment_date, null: false                          # Date of the new balance entry
      t.references :associated_transaction, null: false, foreign_key: { to_table: :transactions }  # Reference to the transaction

      t.timestamps
    end
  end
end
