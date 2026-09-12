# Extends Omen::Reading with the one exchange that turns a question into an answer.
module Omen::Executed extend ActiveSupport::Concern
  # A database message can quote a row, so only the kind of failure is passed on.
  REFUSED = 'so ask it a different way'

private

  # Read again each time round, so a question asked while the API was answering is picked up.
  def run
    with_lock { return if started? && fresh?; started! }
    while (question = questions.where.missing(:answer).first)
      answer question
    end
    completed!
  rescue StandardError => error
    Rails.logger.warn "Reading #{id} failed: #{error.class}"
    failed!
  end

  def answer(question)
    reply = Omen::Conversation.new(asked_up_to(question), self).advance
    increment! :input_usage, reply[:input_usage]
    increment! :output_usage, reply[:output_usage]
    execute question.create_answer!(**reply)
  end

  # The last few turns rather than every one: a thread nobody clears would otherwise carry its
  # whole history into each question, and be charged for it again each time.
  def asked_up_to(question)
    asked = questions.where id: ..question.id
    asked.where id: asked.reorder(id: :desc).limit(Omen.config.remembered).select(:id)
  end

  def execute(answered)
    return if answered.sql.blank?

    answered.update! Omen::Query.new(answered.sql, self).answer
  rescue Omen::Role::Unavailable => error
    answered.update! error: error.message
  rescue StandardError => error
    Rails.logger.warn "Reading #{id} refused a statement: #{error.class}"
    answered.update! error: "#{(error.cause || error).class}, #{REFUSED}"
  end
end
