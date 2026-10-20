require "test_helper"

class NextQuestionTest < ActiveSupport::TestCase
  test "skips recently seen questions and returns nil once a category is exhausted" do
    user = users(:one)
    everything = categories(:everything)

    first = NextQuestion.call(user:, category: everything)
    second = NextQuestion.call(user:, category: everything, exclude_ids: [ first.id ])

    assert_not_equal first, second
    assert_nil NextQuestion.call(user:, category: everything, exclude_ids: [ first.id, second.id ])
  end
end
