# Extends Omen::Reading with the way a question is added to it.
module Omen::Asked extend ActiveSupport::Concern
  # Records what was typed, which is what sets a run going.
  # @param question [String] what the asker wants to know.
  # @return [Omen::Question] the question that was added.
  def ask(question) = questions.create! content: [ { type: 'text', text: question } ]

  # @return [Boolean] whether Claude is still working on the last question.
  def answering? = (unstarted? || started?) && fresh?
end
