class CategoriesController < ApplicationController
  allow_unauthenticated_access

  def index
    @categories = Category.main.by_size.where("questions_count > 0")
    @my_ratings = authenticated? ? Current.user.user_ratings.index_by(&:category_id) : {}
  end

  def show
    @category = Category.find(params[:id])
    @leaders = @category.user_ratings.leaderboard.includes(:user).limit(25)
    @hardest = @category.question_ratings.order(rating: :desc).includes(:question).limit(10)
    @my_rating = Current.user&.user_ratings&.find_by(category: @category) if authenticated?
  end
end
