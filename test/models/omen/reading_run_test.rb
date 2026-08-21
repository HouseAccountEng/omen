require 'test_helper'

# The one exchange that turns a question into an answer, and what a run does when it cannot.
class Omen::ReadingRunTest < ActiveSupport::TestCase
  test 'a question is answered, the statement it came back with is run, and the reading closes' do
    stub_claude claude_answers(sql: 'SELECT city, count(*) AS homes FROM homes GROUP BY city',
                              note: 'One row per city, with how many homes are in it.')

    reading = ask 'Where are the homes we serve?'

    assert reading.completed?
    assert_equal 'One row per city, with how many homes are in it.', answer(reading).note
    assert_equal 2, answer(reading).result.sole['homes']
    assert_equal 10, reading.input_usage
    assert_equal 5, reading.output_usage
  end

  # The bug the split fixed. An answer is inserted after the API call, so a question asked
  # during one lands after it, and a run that read the log up front saw an answer last, exited,
  # and left that question unanswered forever -- its own run having found the reading claimed.
  test 'a question asked while Claude was answering is picked up by the same run' do
    reading = Omen::Reading.create! question: 'Where are the homes we serve?'
    asked = 'And how many bookings are there?'
    stub_request(:post, Omen::Stubs::MESSAGES_URL).to_return do
      reading.ask asked if reading.questions.count == 1
      { body: claude_answers(note: 'Which days did you mean?').to_json,
        headers: { 'Content-Type' => 'application/json' }, }
    end

    perform_enqueued_jobs

    assert_equal [ 'Where are the homes we serve?', asked ], reading.questions.map(&:text)
    assert_equal 2, Omen::Answer.count
    assert reading.reload.completed?
  end

  test 'a statement the database refuses says what kind of failure it was, and quotes no row' do
    stub_claude claude_answers(sql: 'INSERT INTO bookings DEFAULT VALUES', note: 'Adds one.')

    reading = ask 'Add a booking'

    assert_equal "PG::SyntaxError, #{Omen::Executed::REFUSED}", answer(reading).error
    assert reading.completed?
    assert_equal 2, Booking.count
  end

  # A failure of ours must never reach the asker as a failure of the question they typed.
  test 'a role the database has not got says the app is misconfigured, not the question' do
    renamed = "ALTER ROLE #{Omen.config.narrow_role} RENAME TO absent"
    ApplicationRecord.with_connection { |connection| connection.execute renamed }
    stub_claude claude_answers(sql: 'SELECT count(*) FROM bookings', note: 'How many there are.')

    reading = ask 'How many bookings are there?'

    assert_equal Omen::Role::MISCONFIGURED, answer(reading).error
    assert_not_includes answer(reading).error, Omen::Executed::REFUSED
    assert_empty answer(reading).result
  end

  test 'a question Claude reads two ways comes back as a question, with no statement run' do
    stub_claude claude_answers(note: 'How many of what, and over which days?')

    reading = ask 'How many?'

    assert_equal 'How many of what, and over which days?', answer(reading).note
    assert_equal '', answer(reading).sql
    assert_empty answer(reading).result
    assert reading.completed?
  end

  test 'a question the API will not take fails the reading rather than leaving it answering' do
    stub_request(:post, Omen::Stubs::MESSAGES_URL).to_return status: 400, body: '{}'

    reading = ask 'Anything at all'

    assert reading.failed?
    assert_not reading.answering?
    assert_nil answer(reading)
  end

  test 'a reading another run has already claimed is left to it' do
    reading = Omen::Reading.create! question: 'Where are the homes we serve?'
    reading.started!

    perform_enqueued_jobs

    assert_not_requested :post, Omen::Stubs::MESSAGES_URL
    assert reading.reload.started?
  end

private

  def ask(question)
    reading = Omen::Reading.create! question: question
    perform_enqueued_jobs
    reading.reload
  end

  def answer(reading) = reading.questions.first.answer
end
