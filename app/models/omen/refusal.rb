# What a Postgres role may not read: the tables it holds no SELECT on, and the columns of the
# rest that a column-level grant left out. Each is asked of a role the database has to have, so
# a name it does not know refuses nothing here -- the statement is what says the app is
# misconfigured, in the one message that case is owed.
class Omen::Refusal
  # Every column of the app the role is refused. Asked of the column rather than of the table,
  # since a grant naming columns leaves the table itself ungranted and every one of these true.
  COLUMNS = <<~SQL
    SELECT c.relname, a.attname FROM pg_roles r, pg_class c
      JOIN pg_namespace n ON n.oid = c.relnamespace
      JOIN pg_attribute a ON a.attrelid = c.oid AND a.attnum > 0 AND NOT a.attisdropped
     WHERE r.rolname = ? AND n.nspname = 'public' AND c.relkind = 'r'
       AND NOT has_column_privilege(r.oid, c.oid, a.attnum, 'SELECT')
  SQL

  # Every table of it none of whose columns the role may read, this gem's own included.
  TABLES = <<~SQL
    SELECT c.relname FROM pg_roles r, pg_class c
      JOIN pg_namespace n ON n.oid = c.relnamespace
     WHERE r.rolname = ? AND n.nspname = 'public' AND c.relkind = 'r'
       AND NOT EXISTS (SELECT 1 FROM pg_attribute a
                        WHERE a.attrelid = c.oid AND a.attnum > 0 AND NOT a.attisdropped
                          AND has_column_privilege(r.oid, c.oid, a.attnum, 'SELECT'))
  SQL

  # @param role [String] the Postgres role a statement will run as.
  def initialize(role)
    @role = role
  end

  # @return [Array<String>] the tables it may not read.
  def tables = Omen.tables | asked(TABLES).flatten

  # @return [Array<Array<String>>] the table and column of each one it may not read.
  def columns = asked COLUMNS

private

  def asked(sql)
    named = Omen.config.record.sanitize_sql_array [ sql, @role ]
    Omen.config.record.with_connection { |connection| connection.select_rows named }
  end
end
