# Creates the Postgres role a read-only request logs in as. Omen has no name for this role and
# no business creating it, so a host does it -- and this app is the host Omen is tested in.
module Reader
  # The role the 'reader' entry of config/database.yml connects as.
  ROLE = 'omen_dummy_reader'

  # What a read-only role may never be: a superuser bypasses GRANT outright.
  ATTRIBUTES = 'NOSUPERUSER NOCREATEDB NOCREATEROLE NOBYPASSRLS NOREPLICATION'

  # Grants on every database this environment prepares.
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

  # Warns rather than raises, so a database that forbids CREATE ROLE still prepares.
  # @param connection [ActiveRecord::ConnectionAdapters::AbstractAdapter] a writing one.
  # @return [void]
  def self.grant_on(connection)
    statements(connection).each { |statement| connection.execute statement }
    puts "Granted SELECT on #{connection.current_database} to #{ROLE}"
  rescue ActiveRecord::StatementInvalid => error
    warn "Could not grant to #{ROLE}, so a read-only request will fail: #{error.message}"
  end

  # @param connection [ActiveRecord::ConnectionAdapters::AbstractAdapter] a writing one.
  # @return [Array<String>] the statements to run, in order.
  def self.statements(connection)
    role = connection.quote_table_name ROLE
    database = connection.quote_table_name connection.current_database
    [
      "DO $$ BEGIN IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = #{connection.quote ROLE}) " \
        "THEN CREATE ROLE #{role} LOGIN; END IF; END $$",
      "ALTER ROLE #{role} WITH LOGIN #{ATTRIBUTES} PASSWORD 'reader'",
      "ALTER ROLE #{role} SET default_transaction_read_only = on",
      "GRANT CONNECT ON DATABASE #{database} TO #{role}",
      'GRANT USAGE ON SCHEMA public TO ' + role,
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
granted = Rake::Task['db:reader:grant']

%w[ db:create db:prepare db:reset db:test:prepare ].each do |name|
  Rake::Task[name].enhance do
    granted.reenable
    granted.invoke
  end
end
