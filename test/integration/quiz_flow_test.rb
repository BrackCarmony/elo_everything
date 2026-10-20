require "test_helper"

class QuizFlowTest < ActionDispatch::IntegrationTest
  test "sign up, answer a question, see the rating change" do
    post registration_path, params: { user: { display_name: "Brack", email_address: "brack@example.com", password: "secret123", password_confirmation: "secret123" } }
    assert_redirected_to root_path

    science = categories(:science)
    get category_play_path(science)
    assert_response :success
    assert_select "h1.question", questions(:water).body

    post category_answers_path(science), params: { question_id: questions(:water).id, answer: "H2O" }
    attempt = Attempt.last
    assert_redirected_to attempt_path(attempt, category_id: science.id)

    follow_redirect!
    assert_select ".verdict", "Correct!"
    assert_operator User.find_by!(email_address: "brack@example.com").user_ratings.find_by!(category: science).rating, :>, 1200
  end

  test "an answer for a question that wasn't asked is rejected" do
    sign_in_as users(:one)
    science = categories(:science)

    post category_answers_path(science), params: { question_id: questions(:water).id, answer: "H2O" }

    assert_redirected_to category_play_path(science)
    assert_equal 0, Attempt.count
  end

  test "the home page lists main categories without signing in" do
    get root_path
    assert_response :success
    assert_select ".tile-name", text: "Science"
    assert_select ".tile-name", text: "Chemistry", count: 0
  end
end
