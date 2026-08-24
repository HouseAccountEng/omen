require 'test_helper'

# The function every timestamp in a reading's statement is read through.
class Omen::TimeZoneTest < ActiveSupport::TestCase
  # 18:10 UTC is 14:10 in New York, and the same moment given either way has to answer the same
  # thing. A body that names an instant UTC before rendering it converts twice and says 22:10.
  # Cast to text, since Active Record would hand a timestamp back as a Time and hide the string.
  test 'a stored timestamp and the same moment as an instant agree' do
    ApplicationRecord.with_connection do |connection|
      Omen::TimeZone.statements(connection).each { |statement| connection.execute statement }
      stored, instant = connection.select_rows(<<~SQL).first
        SELECT omen_time_zone(timestamp '2026-08-24 18:10:00')::text,
               omen_time_zone(timestamptz '2026-08-24 18:10:00+00')::text
      SQL

      assert_equal '2026-08-24 14:10:00', stored
      assert_equal stored, instant
    end
  end

  # Postgres will not cast an instant to a timestamp to resolve a call, so a reply reaching for
  # now() finds no function at all unless both are declared. The refusal aborts its transaction,
  # so it is asked for inside a savepoint of its own.
  test 'an instant resolves a call, which one declaration alone would refuse' do
    ApplicationRecord.with_connection do |connection|
      connection.execute Omen::TimeZone.stored connection
      connection.execute 'DROP FUNCTION IF EXISTS omen_time_zone(timestamptz)'

      assert_raises ActiveRecord::StatementInvalid do
        connection.transaction requires_new: true do
          connection.select_value 'SELECT omen_time_zone(now())'
        end
      end

      connection.execute Omen::TimeZone.instant connection

      assert_not_nil connection.select_value 'SELECT omen_time_zone(now())'
    end
  end

  # The whole point of the function: a window built on it answers for the month it is run in.
  # A formula built on a literal cannot, which is what a stored statement used to carry.
  test 'a window built on today slides, and today is the company day' do
    ApplicationRecord.with_connection do |connection|
      Omen::TimeZone.statements(connection).each { |statement| connection.execute statement }

      assert_equal Date.current, connection.select_value('SELECT omen_today()')
      last = connection.select_value "SELECT date_trunc('month', omen_today()) - interval '1 month'"

      assert_equal Date.current.beginning_of_month - 1.month, last.to_date
    end
  end

  # STABLE, never IMMUTABLE. Marked immutable, Postgres may fold it to a constant and the window
  # this function exists to move would stop moving -- which no assertion about its value catches.
  test 'today is stable, so nothing is entitled to fold it away' do
    ApplicationRecord.with_connection do |connection|
      connection.execute Omen::TimeZone.today connection

      volatility = connection.select_value <<~SQL.squish
        SELECT provolatile FROM pg_proc
        WHERE proname = #{connection.quote Omen::Instructions::TODAY}
      SQL

      assert_equal 's', volatility
    end
  end
end
