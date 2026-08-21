# The one place Claude is spoken to, so everything above it is ours to read and to test.
class Omen::Conversation
  # How many tokens one reply may run to. Thinking is on by default and spends from the same
  # budget, so this is sized well past the JSON it has to leave room for.
  MAX_TOKENS = 16_000

  # What each kind of block may carry back in, since a reply handed back whole is a 400.
  SENDABLE = {
    'text' => %w[ type text ],
    'thinking' => %w[ type thinking signature ],
    'redacted_thinking' => %w[ type data ],
    'tool_use' => %w[ type id name input ],
    'tool_result' => %w[ type tool_use_id content is_error ],
  }

  # @param questions [ActiveRecord::Relation] the questions asked so far, oldest first, up to
  #   and including the one being answered.
  def initialize(questions)
    @questions = questions
  end

  # No tools are sent, by design: a tool_result block would be rows travelling back to Claude.
  # @return [Hash] the blocks Claude answered with, why it stopped, and what it cost.
  def advance
    said = client.messages.create model: Omen.config.claude_model, max_tokens: MAX_TOKENS,
      system_: Omen::Instructions.block, messages: messages,
      output_config: Omen::Instructions.output_config

    { content: said.content.map { |block| block.to_h.deep_stringify_keys },
      stop_reason: said.stop_reason, input_usage: said.usage.input_tokens,
      output_usage: said.usage.output_tokens,
    }
  end

private

  def client = Anthropic::Client.new(**credentials)

  # Omitted rather than nil, which would lose the SDK's own resolution of a key.
  def credentials = { api_key: Omen.config.api_key }.compact

  def messages
    spoken.map { |said| { role: said.role, content: said.content.map { |block| sendable block } } }
  end

  def spoken
    @questions.includes(:answer).flat_map { |question| [ question, question.answer ].compact }
  end

  def sendable(block) = block.slice(*SENDABLE.fetch(block['type'], block.keys))
end
