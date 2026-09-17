module Omen
  # What a Postgres role may and may not be. A role is created with every dangerous attribute
  # already off, so this gem sets only what whoever created it may set, and reads the rest back
  # rather than asserting them: saying `NOSUPERUSER` needs the SUPERUSER attribute, so a managed
  # database refuses the very statement that would have made the role safe.
  module Attributes
    # Set on the role, because whoever may create a role may set these.
    SETTABLE = 'NOCREATEDB NOCREATEROLE'

    # Read back instead, since saying no to one of these needs the attribute itself.
    DANGEROUS = { rolsuper: 'SUPERUSER', rolbypassrls: 'BYPASSRLS',
                  rolreplication: 'REPLICATION', }

    # @param login [Boolean] whether anything connects as the role.
    # @return [String] what an ALTER ROLE may assert against any database, managed or not.
    def self.settable(login: false) = "#{login ? 'LOGIN' : 'NOLOGIN'} #{SETTABLE}"

    # @param connection [ActiveRecord::ConnectionAdapters::AbstractAdapter] a writing one.
    # @param name [String] the role to ask about.
    # @return [Boolean] whether the role is there at all to be granted anything.
    def self.exists?(connection, name) = held(connection, name).present?

    # Nil where there is no such role, so that an empty list and a missing role read apart.
    # @param connection [ActiveRecord::ConnectionAdapters::AbstractAdapter] a writing one.
    # @param name [String] the role to ask about.
    # @return [Hash, nil] the row of what the role is, or nothing where the role is not.
    def self.held(connection, name)
      connection.select_one <<~SQL.squish
        SELECT #{DANGEROUS.keys.join ', '} FROM pg_roles
        WHERE rolname = #{connection.quote name}
      SQL
    end

    # @param connection [ActiveRecord::ConnectionAdapters::AbstractAdapter] a writing one.
    # @param name [String] the role to ask about.
    # @return [Array<String>] what the role holds that no read-only request should reach.
    def self.dangerous(connection, name)
      row = held(connection, name) || {}
      DANGEROUS.filter_map { |column, attribute| attribute if row[column.to_s] }
    end
  end
end
