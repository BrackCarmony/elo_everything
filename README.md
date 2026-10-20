# Elo Everything (Rails)

A Rails 8 rebuild of [Elo Everything](https://github.com/BrackCarmony/eloEverything), the 2015 Node/Angular/Mongo quiz app.
Every player and every question has an Elo rating **per category**. Answering a question is a match: the player gains
exactly what the question loses, in every category the question is tagged with.

## Running it

```sh
brew install ruby postgresql@17 && brew services start postgresql@17
export PATH="/opt/homebrew/opt/ruby/bin:/opt/homebrew/opt/postgresql@17/bin:$PATH"
bundle install            # gems install into vendor/bundle
bin/rails db:setup        # create, migrate, seed the demo account (db/seeds.rb)
bin/rails elo:import      # 17,652 questions + 4,636 categories from ~/side/elo-db-dump (about 5s)
bin/rails server
bin/rails test
```

## Where things live

| Piece | File |
|---|---|
| Elo math (ported from `questionsController.js`) | `app/services/elo.rb` |
| Scoring an answer: rating updates, counters, attempt log, in one locked transaction | `app/services/answer_question.rb` |
| Picking a question near the player's rating, widening the window if needed | `app/services/next_question.rb` |
| Mongo dump → Postgres import (BSON, `upsert_all`, idempotent on `mongo_id`) | `lib/tasks/import.rake` |
| Schema | `db/schema.rb` |
| Quiz flow: `plays#show` → `answers#create` → redirect to `attempts#show` | `app/controllers/` |

## The formula

```
p        = 1 / (1 + 10^((question_rating - player_rating) / 400))   # chance the player knows it
expected = p + (1 - p) / choices                                      # plus a lucky guess
change   = 15 * (score - expected)                                    # score: 1 right, 0 wrong, 1/choices for a pass
```

## Mongo → Postgres decisions (good interview material)

- **Embedded arrays became tables.** Mongo stored `scores: [{_category, score}]` inside each question and user.
  Here they're `question_ratings` and `user_ratings` with a unique `(owner, category)` index and a `(category_id, rating)`
  index, so "find a question rated 1100–1300 in Science" is an index range scan instead of an `$elemMatch` over every document.
- **Concurrency.** The old app read, mutated and saved documents with no locking, so two players answering the same question
  at once could lose an update. `AnswerQuestion` runs in a transaction and takes row locks (`SELECT … FOR UPDATE`) on the ratings it changes.
- **Answer integrity.** The old API trusted whatever question id the client sent. Now the server remembers which question it asked
  (`session[:current_question_id]`) and rejects answers to anything else.
- **Wrong-answer stats** were a positional array (`wrong[i]` for `possible_answers[i]`), which breaks if answers are edited.
  They're now a `jsonb` hash keyed by the answer text.
- **The import is an external-data sync in miniature.** Each row keeps its `mongo_id` with a unique index, and `upsert_all` makes the task
  safe to re-run. The same pattern applies to syncing inventory from a partner's API.
- **Users weren't imported.** They hold personal data (emails, Facebook ids) the app doesn't need.

## Ideas to extend

- Question submission and complaints (the dump has 410 complaints).
- A rating-history chart per category from `attempts.rating_changes`.
- Hotwire: swap the result in place with a Turbo Frame instead of a redirect.
- Background job (Solid Queue) to recompute `categories.questions_count`.
