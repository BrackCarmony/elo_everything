class Question < ApplicationRecord
  has_many :question_ratings, dependent: :destroy
  has_many :categories, through: :question_ratings
  has_many :attempts, dependent: :destroy
  belongs_to :creator, class_name: "User", optional: true

  validates :body, :correct_answer, presence: true
  validate :has_wrong_answers

  # Correct answer mixed in with the wrong ones, in random order.
  def shuffled_answers = (wrong_answers + [ correct_answer ]).shuffle

  # Number of choices shown, used by the Elo formula for the chance of a lucky guess.
  def choice_count = wrong_answers.size + 1

  def correct?(answer) = answer.to_s.strip == correct_answer.strip

  # The old app stored S3 keys like "eloeverything/abc.png" and prefixed the S3 host in its templates.
  def picture_src
    return if picture_url.blank?
    picture_url.start_with?("http://", "https://") ? picture_url : "https://s3.amazonaws.com/#{picture_url}"
  end

  private

  def has_wrong_answers
    errors.add(:wrong_answers, "needs at least one wrong answer") if wrong_answers.blank?
  end
end
