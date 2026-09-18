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

    # Said where an audience's own role could not be made. Its tables are then granted to
    # nobody and no policy stands over them, so every reading of that audience says the app is
    # misconfigured -- and every statement after the refusal fails for the same reason, which
    # is one message worth saying and a screenful worth not.
    UNNARROWED = 'Could not make %{role}, so nothing was narrowed to it and every reading of ' \
                 'that audience will say this app is misconfigured. Ask for that role, NOLOGIN.'

    # Said where a role that already existed is one a reading should not be able to reach through.
    DANGEROUS = '%{role} holds %{held}. This gem cannot take that away without being a superuser ' \
                'itself, so ask for it to be taken away.'

    # Creates the role and the functions, and writes every narrowing a host declared, on every
    # database this environment prepares.
    # @return [void]
    def self.grant = Omen.each_database { |connection| grant_on connection }

    # Takes every narrowing back off, leaving each table read the way it was read before one.
    # @return [void]
    def self.widen
      Omen.each_database do |connection|
        Omen::Reading.narrowings.each do |narrowing|
          narrowing.widening(connection).each { |group| Omen.attempted connection, *group }
          puts "Widened #{connection.current_database} back out of #{narrowing.role}"
        end
      end
    end

    # Warns rather than raises: a managed database never grants CREATEROLE, and a deploy that
    # cannot make the role must still finish, having said what has to be made by hand.
    # @param connection [ActiveRecord::ConnectionAdapters::AbstractAdapter] a writing one.
    # @return [void]
    def self.grant_on(connection)
      read_by = reader
      warn UNGRANTED % { role: Omen.config.reading_role } unless read_by
      members = [ read_by, connection.select_value(WHOEVER) ].compact
      Grants.statements(connection, members).each { |it| Omen.attempted connection, it }
      role = Omen.config.narrow_role
      return warn UNMADE % { role: role, tables: Omen.tables.to_sentence } unless
        Attributes.exists? connection, role

      held = Attributes.dangerous connection, role
      warn DANGEROUS % { role: role, held: held.to_sentence } if held.any?
      puts "Granted SELECT on #{connection.current_database} to #{role}"
      narrow connection, members
    end

    # Every audience a host declared, written into the database its readings are answered from.
    # @param connection [ActiveRecord::ConnectionAdapters::AbstractAdapter] a writing one.
    # @param members [Array<String>] the roles that may enter a narrowed one.
    # @return [void]
    def self.narrow(connection, members)
      Omen::Reading.narrowings.each { |narrowing| narrowed connection, narrowing, members }
    end

    # One audience: its role made first and asked for straight after, since everything else
    # here names that role and a database that would not make it refuses the lot. Nothing is
    # said to have been narrowed where nothing was.
    # @param connection [ActiveRecord::ConnectionAdapters::AbstractAdapter] a writing one.
    # @param narrowing [Omen::Narrowing] the audience to write.
    # @param members [Array<String>] the roles that may enter its role.
    # @return [void]
    def self.narrowed(connection, narrowing, members)
      making, *holding = narrowing.statements(connection, members)
      Omen.attempted connection, *making
      return warn UNNARROWED % { role: narrowing.role } unless
        Attributes.exists? connection, narrowing.role

      holding.each { |group| Omen.attempted connection, *group }
      puts "Narrowed #{narrowing.role} to the rows #{narrowing.setting} names"
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
