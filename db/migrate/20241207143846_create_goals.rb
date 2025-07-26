class CreateGoals < ActiveRecord::Migration[7.1]
  def change
    create_table :goals do |t|
      t.string :goal_name, null: false     # Name of the goal
      t.integer :amount, null: false       # Amount in cents
      t.references :category, foreign_key: true, null: false, index: { unique: true }  # Links to Category
      t.datetime :archived_at              # Date when the goal was archived

      t.timestamps
    end
  end
end
