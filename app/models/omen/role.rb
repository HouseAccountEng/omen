# The Postgres role a reading's statement runs as, which is refused the reading's own tables.
class Omen::Role
  # Raised where the database has no such role, or has not granted it to the connecting user.
  class Unavailable < StandardError; end

  # Ours to write, since it quotes no row: what an asker is told when it was the setup that failed.
  MISCONFIGURED = 'This app is misconfigured, not the question -- ask an engineer to install ' \
                  'the read-only role a statement runs as.'

  # @param connection [ActiveRecord::ConnectionAdapters::AbstractAdapter] the one to switch.
  # @param name [String] the role to enter.
  # @param settings [Hash] what to set first, which a row policy may read to scope the rows.
  def initialize(connection, name, settings = {})
    @connection = connection
    @name = name
    @settings = settings
  end

  # Given up before anything of ours runs; a statement Postgres refused rolls it back instead.
  # @return [Object] whatever the block answered.
  def around
    enter
    yield.tap { @connection.execute 'SET LOCAL ROLE NONE' }
  end

private

  # Set before the role rather than after it, so a setting is written by the role that holds
  # the rows rather than by the one that is about to be refused them.
  def enter
    @settings.each { |name, value| set name, value }
    @connection.execute "SET LOCAL ROLE #{@connection.quote_table_name @name}"
  rescue ActiveRecord::StatementInvalid
    raise Unavailable, MISCONFIGURED
  end

  # Through set_config, since a name carrying a dot is not one SET LOCAL can be given quoted.
  def set(name, value)
    @connection.raw_connection.exec_params 'SELECT set_config($1, $2, true)', [ name, value.to_s ]
  end
end
