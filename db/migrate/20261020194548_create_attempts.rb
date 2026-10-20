class CreateAttempts < ActiveRecord::Migration[8.1]
  def change
    create_table :attempts do |t|
      t.references :user, null: false, foreign_key: true
      t.references :question, null: false, foreign_key: true
      t.string :outcome, null: false
      t.string :answer
      # [{category_id, category_name, change, user_rating}] for each category the question was rated in
      t.jsonb :rating_changes, null: false, default: []

      t.timestamps
    end
    add_index :attempts, [ :user_id, :created_at ]
  end
end
