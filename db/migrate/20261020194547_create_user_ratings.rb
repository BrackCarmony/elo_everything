class CreateUserRatings < ActiveRecord::Migration[8.1]
  def change
    create_table :user_ratings do |t|
      t.references :user, null: false, foreign_key: true, index: false
      t.references :category, null: false, foreign_key: true, index: false
      t.float :rating, null: false, default: 1200.0
      t.integer :answered_count, null: false, default: 0
      t.integer :correct_count, null: false, default: 0
      t.integer :wrong_count, null: false, default: 0
      t.integer :passed_count, null: false, default: 0

      t.timestamps
    end
    add_index :user_ratings, [ :user_id, :category_id ], unique: true
    add_index :user_ratings, [ :category_id, :rating ]
  end
end
