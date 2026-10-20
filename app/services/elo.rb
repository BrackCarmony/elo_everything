# Elo rating math from the original Elo Everything (server/controllers/questionsController.js).
#
# Players and questions both carry a rating per category. Answering is a "match":
# the player gains what the question loses. Because a multiple-choice question can be
# guessed, the expected score adds the chance of a lucky guess to the chance of knowing it.
module Elo
  K = 15

  module_function

  # score: 1 for correct, 0 for wrong, 1/n for a pass (n = number of choices).
  # Returns how much the player's rating moves; the question moves by the opposite.
  def rating_change(score:, player_rating:, question_rating:, choices:)
    knows_it = 1.0 / (1 + 10**((question_rating - player_rating) / 400.0))
    expected = knows_it + (1 - knows_it) / choices
    K * (score - expected)
  end

  def score_for(outcome, choices:)
    case outcome.to_sym
    when :correct then 1.0
    when :wrong then 0.0
    when :pass then 1.0 / choices
    else raise ArgumentError, "unknown outcome #{outcome.inspect}"
    end
  end
end
