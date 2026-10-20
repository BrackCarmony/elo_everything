require "test_helper"

class AnswerQuestionTest < ActiveSupport::TestCase
  setup do
    @user = users(:one)
    @question = questions(:water)
  end

  test "a correct answer moves the player up and the question down in every category it is rated in" do
    before = @question.question_ratings.pluck(:category_id, :rating).to_h

    attempt = AnswerQuestion.call(user: @user, question: @question, answer: "H2O")

    assert_equal "correct", attempt.outcome
    assert_equal 3, attempt.rating_changes.size
    @question.question_ratings.reload.each do |qr|
      ur = @user.user_ratings.find_by!(category: qr.category)
      gained = ur.rating - UserRating::STARTING_RATING
      assert_operator gained, :>, 0
      assert_in_delta before[qr.category_id] - gained, qr.rating, 1e-9, "question should lose exactly what the player gained"
      assert_equal 1, ur.correct_count
    end
    assert_equal 1, @question.reload.correct_count
  end

  test "a wrong answer is counted against that answer" do
    AnswerQuestion.call(user: @user, question: @question, answer: "CO2")

    assert_equal({ "CO2" => 1 }, @question.reload.wrong_counts)
    assert_operator @user.user_ratings.find_by!(category: categories(:science)).rating, :<, UserRating::STARTING_RATING
  end

  test "a pass is recorded as a pass" do
    attempt = AnswerQuestion.call(user: @user, question: @question, pass: true)

    assert_equal "pass", attempt.outcome
    assert_equal 1, @question.reload.passed_count
    assert_equal 1, @user.user_ratings.find_by!(category: categories(:everything)).passed_count
  end
end
