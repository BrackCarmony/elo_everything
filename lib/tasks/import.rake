require "bson"

namespace :elo do
  desc "Import categories and questions from the old Mongo dump. DUMP_DIR defaults to ~/side/elo-db-dump/elo-dump/elo"
  task import: :environment do
    dir = ENV.fetch("DUMP_DIR", File.expand_path("~/side/elo-db-dump/elo-dump/elo"))
    read = lambda do |name|
      bytes = File.binread(File.join(dir, "#{name}.bson"))
      buffer = BSON::ByteBuffer.new(bytes)
      docs = []
      docs << Hash.from_bson(buffer) while buffer.read_position < bytes.bytesize
      docs
    end
    now = Time.current

    # Users are left out on purpose: they hold personal data (emails, Facebook ids) and the app works without them.
    puts "Importing categories..."
    categories = read.("categories").filter_map do |c|
      next if c["name"].blank?
      # The old data has typos like "Gategory" and "Catego" for main categories.
      kind = c["status"].to_s.downcase.start_with?("g", "cat") ? "category" : "tag"
      { name: c["name"].strip.downcase, kind:, mongo_id: c["_id"].to_s, created_at: now, updated_at: now }
    end.uniq { |c| c[:name] }
    Category.upsert_all(categories, unique_by: :mongo_id)
    category_ids = Category.pluck(:mongo_id, :id).to_h

    puts "Importing questions..."
    docs = read.("questions").select { |q| q["question"].present? && q["correct_answer"].present? && q["possible_answers"].present? }
    docs.each_slice(2000) do |batch|
      rows = batch.map do |q|
        wrong = q["possible_answers"].map(&:to_s)
        wrong_counts = wrong.zip(Array(q["wrong"])).to_h { |answer, count| [ answer, count.to_i ] }.select { |_, n| n > 0 }
        {
          body: q["question"], correct_answer: q["correct_answer"].to_s, wrong_answers: wrong,
          picture_url: q["pictureUrl"], answered_count: q["answered"].to_i, correct_count: q["correct"].to_i,
          passed_count: q["passed"].to_i, wrong_counts:, mongo_id: q["_id"].to_s, created_at: now, updated_at: now
        }
      end
      Question.upsert_all(rows, unique_by: :mongo_id)
    end
    question_ids = Question.pluck(:mongo_id, :id).to_h

    puts "Importing question ratings..."
    ratings = docs.flat_map do |q|
      Array(q["scores"]).filter_map do |s|
        category_id = category_ids[s["_category"].to_s] or next
        { question_id: question_ids.fetch(q["_id"].to_s), category_id:, rating: (s["score"] || 1200).to_f, created_at: now, updated_at: now }
      end
    end.uniq { |r| [ r[:question_id], r[:category_id] ] }
    ratings.each_slice(5000) { |batch| QuestionRating.upsert_all(batch, unique_by: [ :question_id, :category_id ]) }

    ApplicationRecord.connection.execute(<<~SQL)
      UPDATE categories SET questions_count = (SELECT count(*) FROM question_ratings WHERE category_id = categories.id)
    SQL

    puts "Done: #{Category.count} categories (#{Category.main.count} main), #{Question.count} questions, #{QuestionRating.count} ratings."
  end
end

namespace :elo do
  desc "Promote every tag that already has Category::PROMOTION_THRESHOLD questions to a main category"
  task promote_tags: :environment do
    ready = Category.tags.where(questions_count: Category::PROMOTION_THRESHOLD..)
    names = ready.order(questions_count: :desc).pluck(:name)
    ready.update_all(kind: "category", updated_at: Time.current)
    puts names.any? ? "Promoted #{names.size}: #{names.join(', ')}" : "No tags are ready."
  end
end
