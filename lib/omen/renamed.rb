module Omen
  # The names these functions had before 1.0, dropped so a database matches the gem installed in
  # it. A statement stored before the rename names them, and dropping them makes re-running one
  # fail where leaving them would have it quietly answer -- from a function nothing maintains any
  # more. An answer already drawn is unaffected: its rows are stored, not recomputed.
  #
  # Delete this file once no database still has them.
  module Renamed
    # Signatures rather than names, since a function is dropped by the arguments it takes.
    BEFORE = [ 'eastern(timestamp)', 'eastern(timestamptz)',
               'miles_between(double precision, double precision, double precision, ' \
               'double precision)', ]

    # @return [Array<String>] one DROP per function this gem used to create.
    def self.statements = BEFORE.map { |signature| "DROP FUNCTION IF EXISTS #{signature}" }
  end
end
