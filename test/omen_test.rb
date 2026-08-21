require 'test_helper'

class OmenTest < ActiveSupport::TestCase
  test 'every setting has a default, so an app that accepts them writes no initializer' do
    assert_equal :reading, Omen.config.reading_role
    assert_equal 'omen_inquirer', Omen.config.narrow_role
    assert_equal 'claude-opus-5', Omen.config.claude_model
    assert_equal 100, Omen.config.maximum_rows
    assert_nil Omen.config.api_key
    assert_equal ApplicationRecord, Omen.config.record
    assert_equal Rails.root.join('db/schema.rb'), Omen.config.schema
  end

  test 'an app that has no notes to add, and no record class of its own, is asked for neither' do
    bare = Omen::Config.new

    assert_equal '', bare.notes
    assert_equal ApplicationRecord, bare.record
  end

  test 'a host may name the record class its own models descend from' do
    named = Omen::Config.new
    named.record_class = 'Omen::Reading'

    assert_equal Omen::Reading, named.record
  end

  test 'a host says what its schema cannot, in a file of its own' do
    assert_includes Omen.config.notes, 'bookings.home_id'
  end

  test 'the three tables a reading is kept in are the ones that have to be hidden' do
    assert_equal %w[ omen_readings omen_questions omen_answers ], Omen.tables
  end
end
