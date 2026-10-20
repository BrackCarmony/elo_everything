# Scores one answer: updates the player's and the question's rating in every category
# the question belongs to, bumps the counters, and logs the attempt.
class AnswerQuestion
  def self.call(...) = new(...).call

  def initialize(user:, question:, answer: nil, pass: false)
    @user = user
    @question = question
    @answer = answer
    @pass = pass
  end

  def call
    outcome = if @pass then :pass elsif @question.correct?(@answer) then :correct else :wrong end
    score = Elo.score_for(outcome, choices: @question.choice_count)

    ApplicationRecord.transaction do
      # Lock this question's ratings so two players answering at once can't overwrite each other.
      question_ratings = @question.question_ratings.includes(:category).lock.to_a
      user_ratings = @user.user_ratings.where(category_id: question_ratings.map(&:category_id)).lock.index_by(&:category_id)

      changes = question_ratings.map do |qr|
        ur = user_ratings[qr.category_id] || @user.user_ratings.build(category: qr.category)
        change = Elo.rating_change(score:, player_rating: ur.rating, question_rating: qr.rating, choices: @question.choice_count)

        ur.rating += change
        ur.record!(outcome)
        ur.save!
        qr.update!(rating: qr.rating - change)

        { "category_id" => qr.category_id, "category_name" => qr.category.name, "change" => change.round(2), "user_rating" => ur.rating.round }
      end

      update_question_counters(outcome)
      @user.attempts.create!(question: @question, outcome: outcome.to_s, answer: @answer, rating_changes: changes)
    end
  end

  private

  def update_question_counters(outcome)
    @question.answered_count += 1
    case outcome
    when :correct then @question.correct_count += 1
    when :pass then @question.passed_count += 1
    when :wrong then @question.wrong_counts = @question.wrong_counts.merge(@answer.to_s => @question.wrong_counts[@answer.to_s].to_i + 1)
    end
    @question.save!
  end
end
