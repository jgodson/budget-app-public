class CreateCategories < ActiveRecord::Migration[7.1]
  def change
    create_table :categories do |t|
      t.string :name, null: false
      t.integer :category_type, null: false # (0: income, 1: expense, 2: savings)
      t.references :parent_category, foreign_key: { to_table: :categories }, index: true, null: true

      t.timestamps
    end

    # Add a unique index to ensure that category names are unique within the same parent category
    add_index :categories, [:name, :parent_category_id], unique: true
  end
end
