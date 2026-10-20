require "test_helper"

class QuestionTest < ActiveSupport::TestCase
  test "picture_src turns an imported S3 key into a full URL" do
    question = Question.new(picture_url: "eloeverything/0w6uFdq2SR15qChV.png")
    assert_equal "https://s3.amazonaws.com/eloeverything/0w6uFdq2SR15qChV.png", question.picture_src
  end

  test "picture_src leaves full URLs alone and is nil without a picture" do
    assert_equal "https://example.com/a.png", Question.new(picture_url: "https://example.com/a.png").picture_src
    assert_nil Question.new.picture_src
  end
end
