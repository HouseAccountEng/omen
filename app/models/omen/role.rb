# The Postgres role a reading's statement runs as, which is refused the reading's own tables.
class Omen::Role
  # Raised where the database has no such role, or has not granted it to the connecting user.
  class Unavailable < StandardError; end

  # Ours to write, since it quotes no row: what an asker is told when it was the setup that failed.
  MISCONFIGURED = 'This app is misconfigured, not the question -- ask an engineer to install ' \
                  'the read-only role a statement runs as.'

  # @param connection [ActiveRecord::ConnectionAdapters::AbstractAdapter] the one to switch.
  def initialize(connection)
    @connection = connection
  end

  # Given up before anything of ours runs; a statement Postgres refused rolls it back instead.
  # @return [Object] whatever the block answered.
  def around
    enter
    yield.tap { @connection.execute 'SET LOCAL ROLE NONE' }
  end

private

  def enter
    @connection.execute "SET LOCAL ROLE #{@connection.quote_table_name Omen.config.narrow_role}"
  rescue ActiveRecord::StatementInvalid
    raise Unavailable, MISCONFIGURED
  end
end
