require "test_helper"

class EloTest < ActiveSupport::TestCase
  test "evenly matched four-choice question: right gains what wrong loses, scaled by the guess chance" do
    # p = 0.5, expected = 0.5 + 0.5/4 = 0.625
    assert_in_delta 15 * (1 - 0.625), Elo.rating_change(score: 1, player_rating: 1200, question_rating: 1200, choices: 4)
    assert_in_delta 15 * (0 - 0.625), Elo.rating_change(score: 0, player_rating: 1200, question_rating: 1200, choices: 4)
  end

  test "beating a harder question is worth more than beating an easier one" do
    hard = Elo.rating_change(score: 1, player_rating: 1200, question_rating: 1600, choices: 4)
    easy = Elo.rating_change(score: 1, player_rating: 1200, question_rating: 800, choices: 4)
    assert_operator hard, :>, easy
    assert_operator easy, :>, 0
  end

  test "passing scores as a random guess, so it sits between right and wrong" do
    pass = Elo.rating_change(score: Elo.score_for(:pass, choices: 4), player_rating: 1200, question_rating: 1200, choices: 4)
    wrong = Elo.rating_change(score: 0, player_rating: 1200, question_rating: 1200, choices: 4)
    right = Elo.rating_change(score: 1, player_rating: 1200, question_rating: 1200, choices: 4)
    assert_operator wrong, :<, pass
    assert_operator pass, :<, right
  end

  test "matches the original JavaScript implementation" do
    # calculateRatingChange(1, 1200, 1220.379, 4) from the old Node app
    p = 1 / (1 + 10**((1220.379 - 1200) / 400.0))
    expected = 15 * (1 - (p + (1 - p) / 4))
    assert_in_delta expected, Elo.rating_change(score: 1, player_rating: 1200, question_rating: 1220.379, choices: 4), 1e-9
  end
end
