module Omen
  # What the role a statement runs as may and may not be. A role is created with every dangerous
  # attribute already off, so this gem sets only what whoever created it may set, and reads the
  # rest back rather than asserting them: saying `NOSUPERUSER` needs the SUPERUSER attribute, so
  # a managed database refuses the very statement that would have made the role safe.
  module Attributes
    # Set on the role, because whoever may create a role may set these.
    SETTABLE = 'NOLOGIN NOCREATEDB NOCREATEROLE'

    # Read back instead, since saying no to one of these needs the attribute itself.
    DANGEROUS = { rolsuper: 'SUPERUSER', rolbypassrls: 'BYPASSRLS',
                  rolreplication: 'REPLICATION', }

    # @param connection [ActiveRecord::ConnectionAdapters::AbstractAdapter] a writing one.
    # @return [Boolean] whether the role is there at all to be granted anything.
    def self.exists?(connection) = held(connection).present?

    # Nil where there is no such role, so that an empty list and a missing role read apart.
    # @param connection [ActiveRecord::ConnectionAdapters::AbstractAdapter] a writing one.
    # @return [Hash, nil] the row of what the role is, or nothing where the role is not.
    def self.held(connection)
      connection.select_one <<~SQL.squish
        SELECT #{DANGEROUS.keys.join ', '} FROM pg_roles
        WHERE rolname = #{connection.quote Omen.config.narrow_role}
      SQL
    end

    # @param connection [ActiveRecord::ConnectionAdapters::AbstractAdapter] a writing one.
    # @return [Array<String>] what the role holds that no reading should be able to reach.
    def self.dangerous(connection)
      row = held(connection) || {}
      DANGEROUS.filter_map { |column, name| name if row[column.to_s] }
    end
  end
end
