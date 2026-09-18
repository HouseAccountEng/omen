module Omen
  # What one audience of a reading may read: the role its statement runs as, the rows each
  # table admits it, and the tables it reads whole because nothing in them is anybody's.
  class Narrowing
    # The policy every role holds, so that turning row level security on takes nothing away
    # from whoever could already read -- a role made after this ran included. The narrowed role
    # is held back by the restrictive policy beside it, which is ANDed with this one and
    # applies to nobody else.
    EVERYBODY = 'omen_everybody'

    # @return [String] the Postgres role a reading of this audience runs as.
    attr_reader :role

    # @return [Symbol] the column of the reading that says whose rows these are.
    attr_reader :by

    # @param role [String] the Postgres role a reading of this audience runs as.
    # @param by [Symbol] the column of the reading that says whose rows these are.
    # @param own [Hash] every table it reads rows of, to what makes a row its own. A table is
    #   named either way, since a host writing one of these writes symbols or strings by habit.
    # @param whole [Array<String>] the tables it reads whole, nobody's in particular.
    # @param except [Regexp, nil] the columns of those it may not read, a counter over everybody
    #   being the case this exists for: it counts every owner rather than this one.
    def initialize(role:, by:, own:, whole: [], except: nil)
      @role = role
      @by = by
      @own = own.transform_keys(&:to_s)
      @whole = whole.map(&:to_s)
      @except = except
    end

    # @return [String] the setting a policy reads to know whose rows it is looking at.
    def setting = "omen.#{@by}"

    # @param connection [ActiveRecord::ConnectionAdapters::AbstractAdapter] a writing one.
    # @param members [Array<String>] the roles that may enter this one.
    # @return [Array<Array<String>>] the statements, grouped: what arrives together is applied
    #   together, so no table is left with row level security on and no policy under it.
    def statements(connection, members)
      [ Grants.made(connection, @role),
        Grants.narrowed(connection, @role, members),
        *@whole.map { |table| granted connection, table },
        *@own.map { |table, own| narrowed connection, table, own }, ]
    end

    # @param connection [ActiveRecord::ConnectionAdapters::AbstractAdapter] a writing one.
    # @return [Array<Array<String>>] the statements that take it back off, table by table.
    def widening(connection)
      @own.keys.map { |table| widened connection, table }
    end

  private

    # The permissive policy first and the table turned on last, so a group that stops short
    # leaves a table nobody has been narrowed on rather than one nobody can read.
    def narrowed(connection, table, own)
      quoted = connection.quote_table_name table
      [ *granted(connection, table),
        *policy(connection, quoted, EVERYBODY, 'FOR ALL TO PUBLIC USING (true) WITH CHECK (true)'),
        *policy(connection, quoted, "#{table}_#{@role}",
          "AS RESTRICTIVE FOR SELECT TO #{connection.quote_table_name @role} " \
          "USING (#{format own, owner: owner, setting: setting})"),
        "ALTER TABLE #{quoted} ENABLE ROW LEVEL SECURITY", ]
    end

    # Dropped first, so that running this again says what it said the first time.
    def policy(connection, quoted, name, rule)
      named = connection.quote_table_name name
      [ "DROP POLICY IF EXISTS #{named} ON #{quoted}",
        "CREATE POLICY #{named} ON #{quoted} #{rule}", ]
    end

    def widened(connection, table)
      quoted = connection.quote_table_name table
      [ "DROP POLICY IF EXISTS #{connection.quote_table_name "#{table}_#{@role}"} ON #{quoted}",
        "DROP POLICY IF EXISTS #{connection.quote_table_name EVERYBODY} ON #{quoted}",
        "ALTER TABLE #{quoted} DISABLE ROW LEVEL SECURITY", ]
    end

    # Empty where the reading names nobody, and no row is nobody's, so nobody reads nothing.
    def owner = "NULLIF(current_setting('#{setting}', true), '')::bigint"

    def granted(connection, table)
      refused = [ Omen::Column::CREDENTIALS, (@except if @whole.include? table) ].compact
      Grants.granted connection, @role, table, Regexp.union(refused)
    end
  end
end
