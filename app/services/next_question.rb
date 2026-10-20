# Picks a question whose rating in the category is close to the player's, skipping recent ones.
# Widens the window if nothing nearby is left, so a very strong or weak player still gets questions.
class NextQuestion
  WINDOWS = [ 100, 200, 400, 800, Float::INFINITY ].freeze

  def self.call(...) = new(...).call

  def initialize(user:, category:, exclude_ids: [])
    @category = category
    @rating = user.user_ratings.find_by(category: category)&.rating || UserRating::STARTING_RATING
    @exclude_ids = exclude_ids
  end

  def call
    WINDOWS.each do |window|
      scope = QuestionRating.where(category: @category)
      scope = scope.where(rating: (@rating - window)..(@rating + window)) if window.finite?
      scope = scope.where.not(question_id: @exclude_ids) if @exclude_ids.any?
      # ORDER BY random() is fine at this size (the largest category has ~17k rows).
      found = scope.order(Arel.sql("random()")).first
      return found.question if found
    end
    nil
  end
end
