require 'test_helper'

# What reaches the Claude API, and what must never reach it.
class Omen::ConversationTest < ActiveSupport::TestCase
  # DO NOT DELETE. A value living only in the fixtures a statement reads, that no question and
  # no line of the schema mentions. This whole feature is the claim that Claude writes the SQL,
  # Rails runs it, and the rows reach the page alone -- so this reaching the API would mean the
  # claim is false.
  UNSENDABLE = 'Beverly Hills'

  # DO NOT DELETE. The same claim for a column the database holds as ciphertext: Rails decrypts
  # it on the way to the page, so the plaintext exists in this process and nowhere else.
  UNSENDABLE_STREET = '2000 North Rodeo Drive'

  test 'a question is sent with the schema and the shape a reply has to take' do
    stub_claude claude_answers(sql: 'SELECT city FROM homes', note: 'Every city.')

    reading = Omen::Reading.create! question: 'Where are the homes we serve?'

    said = answered reading

    assert_equal 'end_turn', said.stop_reason
    assert_equal 'SELECT city FROM homes', said.sql
    assert_equal 'Every city.', said.note
    assert_equal 10, said.input_usage
    assert_equal 5, said.output_usage
    assert_requested :post, Omen::Stubs::MESSAGES_URL do |it|
      it.body.include?('"output_config":{"format":{"type":"json_schema"') &&
        it.body.include?('"ttl":"1h"')
    end
    assert_nothing_replayed
  end

  test 'an answer travels back as the blocks the API will take, and nothing else of itself' do
    stub_claude claude_answers(note: 'Which days did you mean?'),
      claude_answers(sql: 'SELECT count(*) FROM bookings', note: 'How many there are.')
    reading = Omen::Reading.create! question: 'How many?'
    answered reading
    reading.ask 'Since March, then.'

    advance reading

    assert_requested :post, Omen::Stubs::MESSAGES_URL, times: 2
    assert_requested :post, Omen::Stubs::MESSAGES_URL do |it|
      it.body.include?('"role":"assistant"') && it.body.include?('Since March')
    end
    assert_nothing_replayed
  end

  # Two queries whatever the reading holds: the questions, and the answers of all of them.
  test 'a conversation is read in two queries, however many turns it has run to' do
    stub_claude(*Array.new(4) { claude_answers note: 'Which days did you mean?' })
    reading = Omen::Reading.create! question: 'How many?'
    2.times { |asked| answered reading; reading.ask "Since March, then (#{asked})." }

    Omen::Instructions.block # so that reading the schema is not what the count catches

    assert_queries_count 2 do
      Omen::Conversation.new(reading.questions).advance
    end
  end

  test 'a key a host states reaches the API, and one it leaves out is not sent as nothing' do
    Omen.config.api_key = 'sk-ant-whatever'
    stub_claude claude_answers(note: 'Which days did you mean?')

    answered Omen::Reading.create!(question: 'How many?')

    assert_requested :post, Omen::Stubs::MESSAGES_URL,
      headers: { 'X-Api-Key' => 'sk-ant-whatever' }
  ensure
    Omen.config.api_key = nil
  end

  # Cut short at max_tokens, a reply is not JSON at all, whatever the output schema demanded.
  test 'a reply the API stopped mid-sentence reads as an answer with nothing in it' do
    stub_claude claude_says '{"sql": "SELECT 1 AS n", "note": "cut'
    reading = Omen::Reading.create! question: 'Something that runs long'

    said = answered reading

    assert said.cut_off?
    assert_equal '', said.sql
    assert_equal '', said.note
    assert_empty said.combine
  end

private

  def advance(reading) = Omen::Conversation.new(reading.questions).advance

  def answered(reading)
    reading.questions.where.missing(:answer).first.create_answer!(**advance(reading))
  end

  # 'caller' is a stray key the stubbed reply carries, so a reply handed back whole is caught.
  def assert_nothing_replayed
    [ UNSENDABLE, UNSENDABLE_STREET, 'caller', '"tools"', *Omen.tables ].each do |forbidden|
      assert_not_requested(:post, Omen::Stubs::MESSAGES_URL) { |it| it.body.include? forbidden }
    end
  end
end
