require 'test_helper'

# The function a reading measures a radius with, so no reply has to build one out of trigonometry.
class Omen::DistanceTest < ActiveSupport::TestCase
  # A degree of latitude is the same length everywhere, and it is what pins the radius down: at
  # 3958.7613 miles it comes to 69.09. A formula assembled wrongly still answers a number, so the
  # number is what this asserts.
  test 'a degree of latitude is sixty nine miles, whichever way round it is asked' do
    ApplicationRecord.with_connection do |connection|
      Omen::Distance.statements(connection).each { |statement| connection.execute statement }
      north, south, none = connection.select_rows(<<~SQL).first
        SELECT round(omen_miles_between(0, 0, 1, 0)::numeric, 2),
               round(omen_miles_between(1, 0, 0, 0)::numeric, 2),
               omen_miles_between(0, 0, 0, 0)
      SQL

      assert_equal 69.09, north.to_f
      assert_equal north, south
      assert_equal 0.0, none.to_f
    end
  end

  # A host's own column is numeric or real as often as it is a float, and every one of those
  # casts to double precision on its own -- which is why the arguments are declared that way.
  test 'a numeric column is measured without being cast by hand' do
    ApplicationRecord.with_connection do |connection|
      connection.execute Omen::Distance.haversine connection

      measured = connection.select_value <<~SQL
        SELECT round(omen_miles_between(40.7::numeric, -74.0::numeric, 40.8, -74.0)::numeric, 1)
      SQL

      assert_equal 6.9, measured.to_f
    end
  end

  # Nothing is somewhere: a point half given is no point at all.
  test 'a missing coordinate measures nothing rather than zero' do
    ApplicationRecord.with_connection do |connection|
      connection.execute Omen::Distance.haversine connection

      assert_nil connection.select_value 'SELECT omen_miles_between(40.7, NULL, 40.8, -74.0)'
    end
  end
end
