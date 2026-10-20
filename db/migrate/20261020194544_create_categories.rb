class CreateCategories < ActiveRecord::Migration[8.1]
  def change
    create_table :categories do |t|
      t.string :name, null: false
      # "category" (a main subject you can be ranked in) or "tag" (a finer-grained label)
      t.string :kind, null: false, default: "tag"
      t.integer :questions_count, null: false, default: 0
      t.string :mongo_id

      t.timestamps
    end
    add_index :categories, :name, unique: true
    add_index :categories, :mongo_id, unique: true
    add_index :categories, :kind
  end
end
