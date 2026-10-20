class ProfilesController < ApplicationController
  def show
    @user = Current.user
    @ratings = @user.user_ratings.includes(:category).where(categories: { kind: "category" }).order(rating: :desc)
    @attempts = @user.attempts.includes(:question).order(created_at: :desc).limit(20)
  end
end
