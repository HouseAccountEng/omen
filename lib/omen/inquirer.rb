module Omen
  # The Postgres role a reading's own SELECT runs as, blind to the tables a reading is kept in.
  # It needs no database.yml entry of its own: NOLOGIN, it is a privilege container reached
  # with SET LOCAL ROLE and never connected as.
  module Inquirer
    # What this role may never be: a superuser bypasses GRANT outright.
    ATTRIBUTES = 'NOSUPERUSER NOCREATEDB NOCREATEROLE NOBYPASSRLS NOREPLICATION'

    # Whom to ask, since the role a host reads through is one this gem has no name for.
    WHOEVER = 'SELECT current_user'

    # Said on the way through installation step one, where a host has yet to declare the role.
    UNGRANTED = 'No %{role} connection is configured, so nothing was granted to whatever ' \
                'reads through it. Run this again once config/database.yml names one.'

    # Creates the role and the function, on every database this environment prepares.
    # @return [void]
    def self.grant
      environments.each do |environment|
        config = ActiveRecord::Base.configurations.configs_for env_name: environment,
          name: 'primary'
        next unless config
        ActiveRecord::Tasks::DatabaseTasks.with_temporary_connection config do |connection|
          grant_on connection
        end
      end
    end

    # @return [Array<String>] the environments whose databases this run should cover.
    def self.environments = Rails.env.development? ? %w[ development test ] : [Rails.env.to_s]

    # Warns rather than raises: a managed database never grants CREATEROLE, and a deploy that
    # cannot make the role must still finish, having said what has to be made by hand.
    # @param connection [ActiveRecord::ConnectionAdapters::AbstractAdapter] a writing one.
    # @return [void]
    def self.grant_on(connection)
      read_by = reader
      warn UNGRANTED % { role: Omen.config.reading_role } unless read_by
      members = [ read_by, connection.select_value(WHOEVER) ].compact
      statements(connection, members).each { |statement| connection.execute statement }
      puts "Granted SELECT on #{connection.current_database} to #{Omen.config.narrow_role}"
    rescue ActiveRecord::StatementInvalid => error
      warn "Could not make #{Omen.config.narrow_role}, so every reading will say this app is " \
           'misconfigured. Ask for that role, NOLOGIN, granted SELECT on every table but ' \
           "#{Omen.tables.to_sentence}: #{error.message}"
    end

    # Discovered rather than named: SET LOCAL ROLE needs the connecting role to be a member of
    # this one, and the role a host's reading connection logs in as is the host's own business.
    # @return [String, nil] the Postgres user a reading is read through, where there is one.
    def self.reader
      Omen.config.record.connected_to role: Omen.config.reading_role do
        Omen.config.record.with_connection { |connection| connection.select_value WHOEVER }
      end
    rescue ActiveRecord::ConnectionNotDefined, ActiveRecord::ConnectionNotEstablished
      nil
    end

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
        "ALTER ROLE #{role} WITH NOLOGIN #{ATTRIBUTES}",
        "GRANT USAGE ON SCHEMA public TO #{role}",
        "GRANT SELECT ON ALL TABLES IN SCHEMA public TO #{role}",
        "ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON TABLES TO #{role}",
        *members.map { |member| "GRANT #{role} TO #{connection.quote_table_name member}" },
        *revoked(connection, role),
        *Eastern.statements(connection),
        *Distance.statements(connection),
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
