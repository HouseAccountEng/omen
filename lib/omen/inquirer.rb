module Omen
  # The Postgres role a reading's own SELECT runs as, blind to the tables a reading is kept in.
  # It needs no database.yml entry of its own: NOLOGIN, it is a privilege container reached
  # with SET LOCAL ROLE and never connected as.
  module Inquirer
    # Whom to ask, since the role a host reads through is one this gem has no name for.
    WHOEVER = 'SELECT current_user'

    # Said on the way through installation step one, where a host has yet to declare the role.
    UNGRANTED = 'No %{role} connection is configured, so nothing was granted to whatever ' \
                'reads through it. Run this again once config/database.yml names one.'

    # Said where the role could not be made: a managed database never grants CREATEROLE.
    UNMADE = 'Could not make %{role}, so every reading will say this app is misconfigured. Ask ' \
             'for that role, NOLOGIN, granted SELECT on every table but %{tables}.'

    # Said per statement, since the grants, the revocations and the functions need nothing from
    # one another and one refusal should not discard the rest.
    REFUSED = 'Skipped, refused by the database: %{statement} (%{error})'

    # Said where a role that already existed is one a reading should not be able to reach through.
    DANGEROUS = '%{role} holds %{held}. This gem cannot take that away without being a superuser ' \
                'itself, so ask for it to be taken away.'

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
      Grants.statements(connection, members).each { |statement| attempted connection, statement }
      role = Omen.config.narrow_role
      return warn UNMADE % { role: role, tables: Omen.tables.to_sentence } unless
        Attributes.exists? connection

      held = Attributes.dangerous connection
      warn DANGEROUS % { role: role, held: held.to_sentence } if held.any?
      puts "Granted SELECT on #{connection.current_database} to #{role}"
    end

    # One statement at a time, so a database that refuses one still runs the others -- and each
    # inside a savepoint of its own, since a refusal inside a transaction refuses everything
    # after it too, and this task is as likely to be run from a console as from a deploy.
    # @param connection [ActiveRecord::ConnectionAdapters::AbstractAdapter] a writing one.
    # @param statement [String] one of the statements Omen::Grants builds.
    # @return [void]
    def self.attempted(connection, statement)
      connection.transaction(requires_new: true) { connection.execute statement }
    rescue ActiveRecord::StatementInvalid => error
      warn REFUSED % { statement: statement.squish, error: error.message.lines.first.strip }
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
  end
end
