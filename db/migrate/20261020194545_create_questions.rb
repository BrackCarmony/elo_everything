class CreateQuestions < ActiveRecord::Migration[8.1]
  def change
    create_table :questions do |t|
      t.text :body, null: false
      t.string :correct_answer, null: false
      t.jsonb :wrong_answers, null: false, default: []
      t.string :picture_url
      t.integer :answered_count, null: false, default: 0
      t.integer :correct_count, null: false, default: 0
      t.integer :passed_count, null: false, default: 0
      # How many times each wrong answer was picked, keyed by the answer text
      t.jsonb :wrong_counts, null: false, default: {}
      t.references :creator, foreign_key: { to_table: :users }
      t.string :mongo_id

      t.timestamps
    end
    add_index :questions, :mongo_id, unique: true
  end
end
