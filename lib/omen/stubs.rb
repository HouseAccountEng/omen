# Answers the Anthropic API with canned turns, so no test of a host reaches the network.
module Omen::Stubs extend ActiveSupport::Concern
  # Where a message is asked for.
  MESSAGES_URL = 'https://api.anthropic.com/v1/messages'

  # Answers each request with the next turn, so a question and its refinement are scripted apart.
  # @param turns [Array<Hash>] what Claude says, in order.
  def stub_claude(*turns)
    stub_request(:post, MESSAGES_URL).
      to_return(*turns.map { |turn| { body: turn.to_json, headers: json_headers } })
  end

  # Carries a stray `caller`, so a test notices if a reply is ever replayed whole.
  # @param sql [String] the statement Claude answers with, or '' to ask something instead.
  # @param note [String] what Claude says about it.
  # @param combine [Array<Hash>] the columns it asks to be drawn as their parts joined.
  # @return [Hash] a turn where Claude answers in the shape the output schema demands.
  def claude_answers(sql: '', note: '', combine: [])
    answered = { sql: sql, note: note, combine: combine }
    claude_turn 'end_turn', [ { type: 'text', text: answered.to_json,
                                caller: { type: 'assistant' }, } ]
  end

  # A reply cut short at max_tokens is not JSON, whatever the output schema demanded.
  # @param text [String] what Claude got as far as saying.
  # @return [Hash] a turn the API stopped mid-sentence.
  def claude_says(text)
    claude_turn 'max_tokens', [ { type: 'text', text: text } ]
  end

private

  def claude_turn(stop_reason, content)
    { id: 'msg_01', type: 'message', role: 'assistant', model: 'claude-opus-5',
      content: content, stop_reason: stop_reason,
      usage: { input_tokens: 10, output_tokens: 5 },
    }
  end

  def json_headers = { 'Content-Type' => 'application/json' }
end
