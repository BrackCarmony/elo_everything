class AnswersController < ApplicationController
  def create
    @category = Category.find(params[:category_id])
    @question = Question.find(params[:question_id])

    if session.delete(:current_question_id) != @question.id
      return redirect_to category_play_path(@category), alert: "That question expired. Here's a new one."
    end

    attempt = AnswerQuestion.call(user: Current.user, question: @question, answer: params[:answer], pass: params[:pass].present?)
    redirect_to attempt_path(attempt, category_id: @category.id)
  end
end
