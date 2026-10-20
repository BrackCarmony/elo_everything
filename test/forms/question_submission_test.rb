require "test_helper"

class QuestionSubmissionTest < ActiveSupport::TestCase
  def submit(**attrs)
    QuestionSubmission.new(body: "Which planet is largest?", correct_answer: "Jupiter",
                           wrong_answers: [ "Mars", "Venus", "" ], category_names: [ "Science", " astronomy " ],
                           creator: users(:one), **attrs)
  end

  test "creates the question with ratings in its tags plus everything, creating new tags" do
    submission = submit
    assert submission.save

    question = submission.question
    assert_equal %w[Mars Venus], question.wrong_answers
    assert_equal users(:one), question.creator
    assert_equal %w[astronomy everything science], question.categories.pluck(:name).sort
    assert question.question_ratings.all? { |qr| qr.rating == 1200 }
    assert Category.find_by!(name: "astronomy").tag?
    assert_equal 1, Category.find_by!(name: "astronomy").questions_count
    assert_equal 2, categories(:science).reload.questions_count
  end

  test "a picture question is also tagged picture" do
    submission = submit(picture_url: "https://example.com/jupiter.png")
    assert submission.save
    assert_includes submission.question.categories.pluck(:name), "picture"
  end

  test "a tag reaching the threshold becomes a category" do
    categories(:chemistry).update!(questions_count: Category::PROMOTION_THRESHOLD - 1)

    submission = submit(category_names: [ "chemistry" ])
    assert submission.save

    assert_equal [ categories(:chemistry) ], submission.promoted
    assert_equal "category", categories(:chemistry).reload.kind
  end

  test "rejects a missing tag, no wrong answers, or the correct answer listed as wrong" do
    assert_not submit(category_names: [ "", "everything" ]).valid?
    assert_not submit(wrong_answers: [ "", " " ]).valid?
    submission = submit(wrong_answers: [ "jupiter", "Mars" ])
    assert_not submission.valid?
    assert_includes submission.errors[:wrong_answers], "can't include the correct answer"
  end
end
