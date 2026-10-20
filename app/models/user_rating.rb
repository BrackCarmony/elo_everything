class UserRating < ApplicationRecord
  STARTING_RATING = 1200.0

  belongs_to :user
  belongs_to :category

  scope :leaderboard, -> { where("answered_count > 0").order(rating: :desc) }

  def record!(outcome)
    case outcome
    when :correct then self.correct_count += 1
    when :wrong then self.wrong_count += 1
    when :pass then self.passed_count += 1
    end
    self.answered_count += 1
  end
end
