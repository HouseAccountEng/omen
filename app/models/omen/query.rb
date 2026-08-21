# The one SELECT Claude wrote, held by Postgres and by what it grants the role running it.
class Omen::Query
  # Rails writes every timestamp in UTC, which libpq would otherwise read as a local time.
  UTC = { oid: 1114, name: 'timestamp', format: 0 }

  # @param sql [String] the statement Claude answered with.
  def initialize(sql)
    @sql = sql
  end

  # A savepoint, so a statement Postgres rejects leaves the surrounding transaction usable.
  # @return [Hash] the rows, and the encrypted column each header of theirs came from.
  def answer
    record.connected_to role: Omen.config.reading_role do
      record.transaction requires_new: true do
        record.with_connection { |connection| run connection }
      end
    end
  end

private

  def record = Omen.config.record

  def run(connection)
    answered = Omen::Role.new(connection).around { executed connection }
    { result: answered.to_a.first(cap), provenance: Omen::Column.of(answered, connection) }
  end

  def executed(connection)
    raw = connection.raw_connection
    result = raw.exec_params capped, []
    result.type_map = typed raw
    result
  end

  def typed(raw)
    PG::BasicTypeMapForResults.new(raw).tap do |map|
      map.default_type_map = PG::TypeMapAllStrings.new
      map.add_coder PG::TextDecoder::TimestampUtc.new(**UTC)
    end
  end

  def capped = "SELECT * FROM (#{statement}) AS answer LIMIT #{cap}"

  def statement = @sql.strip.delete_suffix ';'

  def cap = Omen.config.maximum_rows + 1
end
