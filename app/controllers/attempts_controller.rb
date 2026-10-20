class AttemptsController < ApplicationController
  def show
    @attempt = Current.user.attempts.includes(:question).find(params[:id])
    @question = @attempt.question
    @category = Category.find_by(id: params[:category_id])
    main_ids = Category.main.where(id: @attempt.rating_changes.map { |c| c["category_id"] }).pluck(:id)
    # Main categories first, then tags; the played category at the top.
    @changes = @attempt.rating_changes.sort_by { |c| [ c["category_id"] == @category&.id ? 0 : 1, main_ids.include?(c["category_id"]) ? 0 : 1, c["category_name"] ] }
    @main_ids = main_ids
  end
end
