require 'test_helper'

class Omen::ReadingTest < ActiveSupport::TestCase
  test 'a reading is opened with the question that prompted it, and reads as that question' do
    reading = Omen::Reading.create! question: 'Where are the homes we serve?'

    assert_equal [ 'Where are the homes we serve?' ], reading.questions.map(&:text)
    assert_equal 'Where are the homes we serve?', reading.to_s
    assert reading.unstarted?
    assert reading.answering?
  end

  test 'a reading nobody has asked anything is refused' do
    assert_not Omen::Reading.new.valid?
  end

  test 'a follow-up joins the reading already open, which still reads as the first question' do
    reading = Omen::Reading.create! question: 'Where are the homes we serve?'
    reading.ask 'And how many bookings are there?'

    assert_equal 2, reading.questions.size
    assert_equal 'Where are the homes we serve?', reading.to_s
    assert_equal %w[ user user ], reading.questions.map(&:role)
  end

  test 'a reading somebody wrote an essay into reads as much of it as a link can carry' do
    reading = Omen::Reading.create! question: 'Which of them ' * 20

    assert_equal 80, reading.to_s.length
  end

  test 'a run that stalled leaves the reading askable again, whatever its status still says' do
    reading = Omen::Reading.create! question: 'Where are the homes we serve?'
    reading.started!
    assert reading.answering?

    reading.update_column :updated_at, Omen::Stated::STALLED_AFTER.ago - 1.minute
    assert_not reading.answering?
    assert reading.started?
  end
end
