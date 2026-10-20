class Attempt < ApplicationRecord
  OUTCOMES = %w[correct wrong pass].freeze

  belongs_to :user
  belongs_to :question

  validates :outcome, inclusion: { in: OUTCOMES }

  def total_change = rating_changes.sum { |c| c["change"] }
end
