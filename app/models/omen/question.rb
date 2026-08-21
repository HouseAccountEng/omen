# A question somebody typed. There is no asked? to check: a question is asked by definition.
class Omen::Question < Omen.config.record
  include Omen::Spoken

  # A question is what sets a run going, and an answer is what a run leaves behind.
  after_create_commit -> { reading.run_later }

  belongs_to :reading, counter_cache: :questions_count, touch: true
  has_one :answer, dependent: :delete

  # @return [String] the side of the conversation this was said on, in the words the API uses.
  def role = 'user'
end
