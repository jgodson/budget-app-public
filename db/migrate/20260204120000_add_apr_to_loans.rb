class AddAprToLoans < ActiveRecord::Migration[7.1]
  def change
    add_column :loans, :apr, :decimal, precision: 5, scale: 2
  end
end
