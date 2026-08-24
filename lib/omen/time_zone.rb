module Omen
  # The zone the company works in, and the two questions a reading asks about it: what a stored
  # timestamp says here, and what day it is here. Created by the rake task rather than by a
  # migration, because Rails' :ruby schema format dumps no functions, so db:schema:load would
  # drop one a migration had made -- and the format cannot become :sql, since db/schema.rb is
  # what Claude is shown.
  module TimeZone
    # The zone as Postgres names one: Time.zone.name is not a name it takes.
    ZONE = 'America/New_York'

    # DDL, which Active Record has no expression for, and not a query.
    # @param connection [ActiveRecord::ConnectionAdapters::AbstractAdapter] a writing one.
    # @return [Array<String>] the statements to run, in order.
    def self.statements(connection) = [ stored(connection), instant(connection), today(connection) ]

    # A stored timestamp says nothing about its own zone, so it is named UTC and then rendered.
    # @param connection [ActiveRecord::ConnectionAdapters::AbstractAdapter] a writing one.
    # @return [String] the statement declaring the function over a naked timestamp.
    def self.stored(connection)
      "CREATE OR REPLACE FUNCTION #{name connection}(ts timestamp) RETURNS timestamp AS " \
        "$$ SELECT ts AT TIME ZONE 'UTC' AT TIME ZONE #{connection.quote ZONE} $$ " \
        'LANGUAGE sql IMMUTABLE'
    end

    # One conversion and not two: an instant already knows which moment it is, so naming it UTC
    # first would convert it twice and answer hours out. Overloaded because Postgres will not
    # cast an instant to a timestamp to resolve a call, so now() reaches neither without it.
    # @param connection [ActiveRecord::ConnectionAdapters::AbstractAdapter] a writing one.
    # @return [String] the statement declaring the function over an instant.
    def self.instant(connection)
      "CREATE OR REPLACE FUNCTION #{name connection}(ts timestamptz) RETURNS timestamp AS " \
        "$$ SELECT ts AT TIME ZONE #{connection.quote ZONE} $$ LANGUAGE sql IMMUTABLE"
    end

    # What makes a window slide: a statement saying `date_trunc('month', omen_today())` answers
    # for whichever month it is run in, where a literal answers for the month it was written in.
    #
    # STABLE and not IMMUTABLE, unlike its neighbours, which are pure functions of what they are
    # given. This one reads the clock: marked immutable, Postgres is entitled to fold it to a
    # constant, and a window would stop moving in the way this function exists to prevent. Stable
    # is also what has it evaluated once per statement, so a query naming it five times cannot
    # straddle midnight.
    #
    # A date and not a timestamp, so a window cannot silently mean "up to the current hour".
    # @param connection [ActiveRecord::ConnectionAdapters::AbstractAdapter] a writing one.
    # @return [String] the statement declaring the function.
    def self.today(connection)
      "CREATE OR REPLACE FUNCTION #{connection.quote_table_name Omen::Instructions::TODAY}() " \
        "RETURNS date AS $$ SELECT (now() AT TIME ZONE #{connection.quote ZONE})::date $$ " \
        'LANGUAGE sql STABLE'
    end

    # @param connection [ActiveRecord::ConnectionAdapters::AbstractAdapter] a writing one.
    # @return [String] the function's name, quoted.
    def self.name(connection) = connection.quote_table_name Omen::Instructions::TIME_ZONE
  end
end
