module Omen
  # The database function a reading's SQL reads every timestamp through. Created by the rake
  # task rather than by a migration, because Rails' :ruby schema format dumps no functions, so
  # db:schema:load would drop one a migration had made -- and the format cannot become :sql,
  # since db/schema.rb is what Claude is shown.
  module Eastern
    # The zone the company works in, as Postgres names one: Time.zone.name is not one it takes.
    ZONE = 'America/New_York'

    # DDL, which Active Record has no expression for, and not a query.
    # @param connection [ActiveRecord::ConnectionAdapters::AbstractAdapter] a writing one.
    # @return [Array<String>] the statements to run, in order.
    def self.statements(connection)
      [ stored(connection), instant(connection) ]
    end

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

    # @param connection [ActiveRecord::ConnectionAdapters::AbstractAdapter] a writing one.
    # @return [String] the function's name, quoted.
    def self.name(connection) = connection.quote_table_name Omen::Instructions::EASTERN
  end
end
