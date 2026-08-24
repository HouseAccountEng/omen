module Omen
  # The database function a reading measures a distance with. Created by the rake task rather
  # than by a migration, for the reason Omen::Eastern is: Rails' :ruby schema format dumps no
  # functions, so db:schema:load would drop one a migration had made.
  module Distance
    # The earth's mean radius in miles, which is what makes the answer miles.
    RADIUS = 3958.7613

    # DDL, which Active Record has no expression for, and not a query.
    # @param connection [ActiveRecord::ConnectionAdapters::AbstractAdapter] a writing one.
    # @return [Array<String>] the statements to run, in order.
    def self.statements(connection) = [ haversine(connection) ]

    # Declared over double precision, which numeric, real and integer all cast to implicitly,
    # so a host's own column type does not have to be guessed at. Any argument NULL and the
    # answer is NULL, the way a distance to nowhere ought to read.
    # @param connection [ActiveRecord::ConnectionAdapters::AbstractAdapter] a writing one.
    # @return [String] the statement declaring the function.
    def self.haversine(connection)
      "CREATE OR REPLACE FUNCTION #{name connection}(lat1 double precision, " \
        'lng1 double precision, lat2 double precision, lng2 double precision) ' \
        "RETURNS double precision AS $$ SELECT 2 * #{RADIUS} * asin(sqrt(" \
        'power(sin(radians(lat2 - lat1) / 2), 2) + cos(radians(lat1)) * cos(radians(lat2)) ' \
        '* power(sin(radians(lng2 - lng1) / 2), 2))) $$ LANGUAGE sql IMMUTABLE'
    end

    # @param connection [ActiveRecord::ConnectionAdapters::AbstractAdapter] a writing one.
    # @return [String] the function's name, quoted.
    def self.name(connection) = connection.quote_table_name Omen::Instructions::MILES
  end
end
