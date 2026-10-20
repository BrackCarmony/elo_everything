require "test_helper"

class QuestionSubmissionFlowTest < ActionDispatch::IntegrationTest
  test "a signed-in player adds a question and can then be asked it" do
    sign_in_as users(:one)
    get new_question_path
    assert_response :success

    assert_difference "Question.count", 1 do
      post questions_path, params: { question_submission: {
        body: "What is the capital of Idaho?", correct_answer: "Boise",
        wrong_answers: [ "Pocatello", "Twin Falls" ], category_names: [ "us capitals" ] } }
    end
    assert_redirected_to new_question_path

    tag = Category.find_by!(name: "us capitals")
    get category_play_path(tag)
    assert_select "h1.question", "What is the capital of Idaho?"
  end

  test "an invalid question re-renders the form with errors and keeps the input" do
    sign_in_as users(:one)
    post questions_path, params: { question_submission: { body: "Half a question", correct_answer: "", wrong_answers: [ "" ], category_names: [ "" ] } }

    assert_response :unprocessable_entity
    assert_select ".errors li", minimum: 2
    assert_select "textarea", "Half a question"
  end
end
