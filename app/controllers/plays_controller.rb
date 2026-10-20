class PlaysController < ApplicationController
  RECENT_LIMIT = 50

  def show
    @category = Category.find(params[:category_id])
    @question = NextQuestion.call(user: Current.user, category: @category, exclude_ids: recent_question_ids)

    if @question
      # Remember what was asked so the answer can't be posted for a different question.
      session[:current_question_id] = @question.id
      @answers = @question.shuffled_answers
      @rating = Current.user.user_ratings.find_by(category: @category)&.rating || UserRating::STARTING_RATING
    else
      redirect_to @category, notice: "You've seen every question in #{@category.name} recently. Try another category."
    end
  end

  private

  def recent_question_ids
    Current.user.attempts.order(created_at: :desc).limit(RECENT_LIMIT).pluck(:question_id)
  end
end
