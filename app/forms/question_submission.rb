# A player-written question: validates the form, creates any new tags, starts the
# question at the default rating in each of its categories, and promotes tags that
# reach Category::PROMOTION_THRESHOLD questions.
class QuestionSubmission
  include ActiveModel::Model
  include ActiveModel::Attributes

  MAX_WRONG_ANSWERS = 9
  MAX_TAGS = 10

  attribute :body, :string
  attribute :correct_answer, :string
  attribute :picture_url, :string
  attribute :wrong_answers, default: -> { [ "", "", "" ] }
  attribute :category_names, default: -> { [ "", "", "" ] }

  attr_accessor :creator
  attr_reader :question, :promoted

  validates :body, presence: true, length: { maximum: 500 }
  validates :correct_answer, presence: true, length: { maximum: 200 }
  validates :picture_url, format: { with: %r{\Ahttps?://\S+\z}, message: "must be a full http(s) link" }, allow_blank: true
  validate :wrong_answers_are_usable
  validate :has_a_tag

  def clean_wrong_answers = Array(wrong_answers).map { |a| a.to_s.strip }.compact_blank.uniq

  # Lowercased, without duplicates or the automatic tags.
  def clean_category_names
    Array(category_names).map { |n| n.to_s.strip.downcase.squish }.compact_blank.uniq - [ Category::EVERYTHING, Category::PICTURE ]
  end

  def save
    return false unless valid?

    ApplicationRecord.transaction do
      @question = Question.create!(body: body.strip, correct_answer: correct_answer.strip, wrong_answers: clean_wrong_answers,
                                   picture_url: picture_url.presence, creator:)
      categories = category_records
      categories.each { |category| @question.question_ratings.create!(category:) }

      # Counters go up in SQL so two people submitting at once don't lose a count.
      Category.where(id: categories.map(&:id)).update_all("questions_count = questions_count + 1")
      @promoted = Category.where(id: categories.map(&:id)).select(&:promote_if_ready!)
    end
    true
  end

  private

  def category_records
    names = clean_category_names + [ Category::EVERYTHING ]
    names << Category::PICTURE if picture_url.present?
    # create_or_find_by! relies on the unique index on name, so two people adding the same new tag at once is safe.
    names.map { |name| Category.find_by(name:) || Category.create_or_find_by!(name:) }
  end

  def wrong_answers_are_usable
    answers = clean_wrong_answers
    if answers.empty?
      errors.add(:wrong_answers, "need at least one entry")
    elsif answers.size > MAX_WRONG_ANSWERS
      errors.add(:wrong_answers, "can have at most #{MAX_WRONG_ANSWERS} entries")
    elsif correct_answer.present? && answers.any? { |a| a.casecmp?(correct_answer.strip) }
      errors.add(:wrong_answers, "can't include the correct answer")
    end
  end

  def has_a_tag
    count = clean_category_names.size
    errors.add(:category_names, "need at least one category or tag") if count.zero?
    errors.add(:category_names, "can have at most #{MAX_TAGS} entries") if count > MAX_TAGS
  end
end
