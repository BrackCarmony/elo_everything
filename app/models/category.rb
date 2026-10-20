class Category < ApplicationRecord
  KINDS = %w[category tag].freeze

  has_many :question_ratings, dependent: :destroy
  has_many :questions, through: :question_ratings
  has_many :user_ratings, dependent: :destroy

  validates :name, presence: true, uniqueness: true
  validates :kind, inclusion: { in: KINDS }

  normalizes :name, with: ->(n) { n.strip.downcase }

  scope :main, -> { where(kind: "category") }
  scope :by_size, -> { order(questions_count: :desc) }

  def self.everything = find_by!(name: "everything")

  def to_param = "#{id}-#{name.parameterize}"
end
