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
      name = connection.quote_table_name Omen::Instructions::EASTERN
      [
        "CREATE OR REPLACE FUNCTION #{name}(ts timestamp) RETURNS timestamp AS " \
          "$$ SELECT ts AT TIME ZONE 'UTC' AT TIME ZONE #{connection.quote ZONE} $$ " \
          'LANGUAGE sql IMMUTABLE',
      ]
    end
  end
end
