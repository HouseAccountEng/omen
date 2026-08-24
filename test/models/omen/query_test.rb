require 'test_helper'

# What happens to the statement Claude writes when it is not a plain answerable SELECT.
class Omen::QueryTest < ActiveSupport::TestCase
  test 'a plain SELECT comes back as rows, and says which header held an encrypted column' do
    answered = answer 'SELECT city, street FROM homes ORDER BY street'

    assert_equal 2, answered[:result].size
    assert_equal 'Beverly Hills', answered[:result].first['city']
    assert_equal({ 'street' => 'homes.street' }, answered[:provenance])
  end

  # The wrapper refuses this one, since an INSERT is not something a SELECT can select from.
  # What the asker is told is the kind of failure, never which of the five layers said no.
  test 'a statement that would write is refused rather than run' do
    assert_raises PG::SyntaxError do
      answer 'INSERT INTO bookings DEFAULT VALUES'
    end

    assert_equal 2, Booking.count
  end

  # A semicolon is legal inside a string literal, so nothing of ours reads the text for one.
  test 'a statement whose only semicolon is inside a string literal runs' do
    answered = answer "SELECT string_agg(name, '; ' ORDER BY name) AS names FROM providers"

    assert_equal 'Jobber Handyman; Local Handyman', answered[:result].sole['names']
  end

  # A balanced paren and a trailing comment close the wrapper, so libpq is what refuses this.
  test 'a second statement smuggled in behind a semicolon is refused by Postgres' do
    assert_raises PG::SyntaxError do
      answer 'SELECT 1) AS answer; SELECT 2 AS second --'
    end

    assert Booking.table_exists?
  end

  # The same escape without a semicolon: it sets its own LIMIT, so only Ruby still holds the cap.
  test 'a statement that closes the wrapper and sets its own LIMIT is capped anyway' do
    answered = answer 'SELECT generate_series(1, 500) AS n) AS answer LIMIT 100000 --'

    assert_equal Omen.config.maximum_rows + 1, answered[:result].size
  end

  # Hidden twice over: out of the schema Claude is shown, and out of what the role the statement
  # runs as may read, so an earlier answer cannot be read back as data.
  test "the tables a reading is kept in are not readable by a reading's own statement" do
    Omen.tables.each do |table|
      refused = assert_raises PG::InsufficientPrivilege do
        answer "SELECT count(*) FROM #{table}"
      end

      assert_includes refused.message, table
    end
  end

  # A stored timestamp is UTC, and libpq would otherwise read one as a local time.
  test 'a timestamp read through the function lands on the wall clock Rails draws' do
    booking = bookings :fulfilled
    booking.update_column :created_at, Time.utc(2026, 8, 13, 1, 30) # no callback wanted
    read = "#{Omen::Instructions::TIME_ZONE}(created_at)"

    answered = answer "SELECT #{read} AS at FROM bookings WHERE id = #{booking.id}"

    drawn = booking.reload.created_at.in_time_zone
    assert_equal '2026-08-12 21:30', drawn.strftime('%F %H:%M')
    assert_equal drawn.strftime('%F %H:%M'), answered[:result].sole['at'].strftime('%F %H:%M')
  end

private

  def answer(sql) = Omen::Query.new(sql).answer
end
