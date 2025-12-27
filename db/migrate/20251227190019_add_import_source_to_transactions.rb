class AddImportSourceToTransactions < ActiveRecord::Migration[7.1]
  def change
    add_column :transactions, :import_source, :string, default: "Existing", null: false
  end
end
