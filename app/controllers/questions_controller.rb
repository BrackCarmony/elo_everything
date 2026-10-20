class QuestionsController < ApplicationController
  def new
    @submission = QuestionSubmission.new
    load_suggestions
  end

  def create
    @submission = QuestionSubmission.new(submission_params)
    @submission.creator = Current.user

    if @submission.save
      notice = "Question added."
      if @submission.promoted.any?
        notice += " #{@submission.promoted.map { |c| c.name.titleize }.to_sentence} reached #{Category::PROMOTION_THRESHOLD} questions and #{@submission.promoted.one? ? 'is' : 'are'} now a category!"
      end
      redirect_to new_question_path, notice:
    else
      load_suggestions
      render :new, status: :unprocessable_entity
    end
  end

  private

  def submission_params
    params.expect(question_submission: [ :body, :correct_answer, :picture_url, wrong_answers: [], category_names: [] ])
  end

  # Existing names for the autocomplete list, biggest first.
  def load_suggestions
    @suggestions = Category.where.not(name: [ Category::EVERYTHING, Category::PICTURE ]).by_size.limit(1500).pluck(:name)
  end
end
