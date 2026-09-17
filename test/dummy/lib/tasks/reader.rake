# Creates the Postgres role a read-only request logs in as. Omen has no name for this role and
# no business creating it, so a host does it -- and this app is the host Omen is tested in. How
# to make one safely is the gem's, which is what everything below leans on.
module Reader
  # The role the 'reader' entry of config/database.yml connects as.
  ROLE = 'omen_dummy_reader'

  # Grants on every database this environment prepares.
  # @return [void]
  def self.grant = Omen.each_database { |connection| grant_on connection }

  # @param connection [ActiveRecord::ConnectionAdapters::AbstractAdapter] a writing one.
  # @return [void]
  def self.grant_on(connection)
    statements(connection).each { |statement| Omen.attempted connection, statement }
    held = Omen::Attributes.dangerous connection, ROLE
    warn "#{ROLE} holds #{held.to_sentence}, so ask for it to be taken away" if held.any?
    puts "Granted SELECT on #{connection.current_database} to #{ROLE}"
  end

  # @param connection [ActiveRecord::ConnectionAdapters::AbstractAdapter] a writing one.
  # @return [Array<String>] the statements to run, in order.
  def self.statements(connection)
    role = connection.quote_table_name ROLE
    database = connection.quote_table_name connection.current_database
    Omen::Grants.made(connection, ROLE, login: true) + [
      "ALTER ROLE #{role} WITH PASSWORD 'reader'",
      "ALTER ROLE #{role} SET default_transaction_read_only = on",
      "GRANT CONNECT ON DATABASE #{database} TO #{role}",
      "GRANT USAGE ON SCHEMA public TO #{role}",
      "GRANT SELECT ON ALL TABLES IN SCHEMA public TO #{role}",
      "ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON TABLES TO #{role}",
    ]
  end
end

namespace :db do
  namespace :reader do
    desc 'Create the read-only role and grant it SELECT on every table'
    task grant: :environment do
      Reader.grant
    end
  end
end

# Held rather than looked up again: a gem's own bin/rails loads this file inside the `app`
# namespace, and the block below runs after that scope is gone. Reenabling matters because
# db:reset invokes db:create on its way through.
granted = [ Rake::Task['db:reader:grant'], Rake::Task['db:omen:grant'] ]

%w[ db:create db:prepare db:reset db:test:prepare ].each do |name|
  Rake::Task[name].enhance do
    granted.each do |task|
      task.reenable
      task.invoke
    end
  end
end
