class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy
  has_many :user_ratings, dependent: :destroy
  has_many :attempts, dependent: :destroy

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  validates :email_address, presence: true, uniqueness: true
  validates :display_name, presence: true, length: { maximum: 40 }

  # The player's rating in a category, or an unsaved one at the starting rating.
  def rating_for(category)
    user_ratings.find_or_initialize_by(category: category)
  end
end
