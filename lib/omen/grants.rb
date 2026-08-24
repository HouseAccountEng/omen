module Omen
  # Everything said to a database to make the role a statement runs as: what it may be, what it
  # may read, and what it may not. Kept apart from the task that runs them, which is about a
  # database it has to find and a refusal it has to survive rather than about privileges.
  module Grants
    # DDL, which Active Record has no expression for, and not a query.
    # @param connection [ActiveRecord::ConnectionAdapters::AbstractAdapter] a writing one.
    # @param members [Array<String>] the roles that may SET LOCAL ROLE to this one. The owner
    #   running the task is one of them, and matters in tests, where Rails swaps the reading
    #   pool for the writing one and the test connection is the owner.
    # @return [Array<String>] the statements to run, in order.
    def self.statements(connection, members)
      role = connection.quote_table_name Omen.config.narrow_role
      [
        'DO $$ BEGIN IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = ' \
          "#{connection.quote Omen.config.narrow_role}) THEN CREATE ROLE #{role} NOLOGIN; " \
          'END IF; END $$',
        "ALTER ROLE #{role} WITH #{Attributes::SETTABLE}",
        "GRANT USAGE ON SCHEMA public TO #{role}",
        "GRANT SELECT ON ALL TABLES IN SCHEMA public TO #{role}",
        "ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON TABLES TO #{role}",
        *members.map { |member| "GRANT #{role} TO #{connection.quote_table_name member}" },
        *revoked(connection, role),
        *Omen::Renamed.statements,
        *Omen::TimeZone.statements(connection),
        *Omen::Distance.statements(connection),
      ]
    end

    # Intersected, so a bare db:create with no table yet to revoke on is not a failure.
    # @param connection [ActiveRecord::ConnectionAdapters::AbstractAdapter] a writing one.
    # @param role [String] the role to hide this feature's own tables from.
    # @return [Array<String>] one REVOKE per table there is.
    def self.revoked(connection, role)
      (connection.tables & Omen.tables).map do |table|
        "REVOKE SELECT ON #{connection.quote_table_name table} FROM #{role}"
      end
    end
  end
end
