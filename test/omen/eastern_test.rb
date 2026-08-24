require 'test_helper'

# The function every timestamp in a reading's statement is read through.
class Omen::EasternTest < ActiveSupport::TestCase
  # 18:10 UTC is 14:10 in New York, and the same moment given either way has to answer the same
  # thing. A body that names an instant UTC before rendering it converts twice and says 22:10.
  # Cast to text, since Active Record would hand a timestamp back as a Time and hide the string.
  test 'a stored timestamp and the same moment as an instant agree' do
    ApplicationRecord.with_connection do |connection|
      Omen::Eastern.statements(connection).each { |statement| connection.execute statement }
      stored, instant = connection.select_rows(<<~SQL).first
        SELECT eastern(timestamp '2026-08-24 18:10:00')::text,
               eastern(timestamptz '2026-08-24 18:10:00+00')::text
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
      connection.execute Omen::Eastern.stored connection
      connection.execute 'DROP FUNCTION IF EXISTS eastern(timestamptz)'

      assert_raises ActiveRecord::StatementInvalid do
        connection.transaction requires_new: true do
          connection.select_value 'SELECT eastern(now())'
        end
      end

      connection.execute Omen::Eastern.instant connection

      assert_not_nil connection.select_value 'SELECT eastern(now())'
    end
  end
end
