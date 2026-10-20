class CreateQuestionRatings < ActiveRecord::Migration[8.1]
  def change
    create_table :question_ratings do |t|
      t.references :question, null: false, foreign_key: true, index: false
      t.references :category, null: false, foreign_key: true, index: false
      t.float :rating, null: false, default: 1200.0

      t.timestamps
    end
    add_index :question_ratings, [ :question_id, :category_id ], unique: true
    # Picking a question near the player's rating is a range scan on this index
    add_index :question_ratings, [ :category_id, :rating ]
  end
end
