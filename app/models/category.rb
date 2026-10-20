class Category < ApplicationRecord
  KINDS = %w[category tag].freeze
  # A tag becomes a main category (shown on the home page, with its own leaderboard) once it has this many questions.
  PROMOTION_THRESHOLD = 100
  # Added to every question; "picture" is also added to questions with an image.
  EVERYTHING = "everything"
  PICTURE = "picture"

  has_many :question_ratings, dependent: :destroy
  has_many :questions, through: :question_ratings
  has_many :user_ratings, dependent: :destroy

  validates :name, presence: true, uniqueness: true
  validates :kind, inclusion: { in: KINDS }

  normalizes :name, with: ->(n) { n.strip.downcase }

  scope :main, -> { where(kind: "category") }
  scope :tags, -> { where(kind: "tag") }
  scope :by_size, -> { order(questions_count: :desc) }

  def self.everything = find_by!(name: EVERYTHING)

  def tag? = kind == "tag"

  # Returns true if this call promoted the tag.
  def promote_if_ready!
    return false unless tag? && questions_count >= PROMOTION_THRESHOLD
    update!(kind: "category")
  end

  def questions_until_promotion = [ PROMOTION_THRESHOLD - questions_count, 0 ].max

  def to_param = "#{id}-#{name.parameterize}"
end
