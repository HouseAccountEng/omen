require 'test_helper'

# A reading narrowed to one owner's rows, which Postgres holds rather than the prompt: a role
# granted the columns that owner may read, and a policy admitting the rows a setting names.
class Omen::ScopedTest < ActiveSupport::TestCase
  setup { narrow }

  test 'the schema shows what the role may read, down to the column' do
    shown = Omen::Schema.new(Consult.new.runs_as).text

    assert_includes shown, 'create_table "providers"'
    assert_includes shown, 't.string "name"'
    assert_not_includes shown, 'access_token'
    assert_not_includes shown, 'create_table "bookings"'
  end

  test "a statement reads the rows the reading's own setting admits, and no others" do
    read = answer 'SELECT name FROM providers ORDER BY name', providers(:local)

    assert_equal [ 'Local Handyman' ], read[:result].map { |row| row['name'] }
  end

  # Every path resolves through the policy, so the shape of the statement changes nothing.
  test 'a statement that asks for every row is answered with the ones that are its own' do
    read = answer 'SELECT count(*) AS all_of_them FROM providers', providers(:jobber)

    assert_equal 1, read[:result].sole['all_of_them']
  end

  test 'a column the grant left out is refused, however the statement asks for it' do
    assert_raises PG::InsufficientPrivilege do
      answer 'SELECT access_token FROM providers', providers(:local)
    end
  end

  # Fail closed: a reading that names nobody reads nothing, rather than everything.
  test 'a reading with no owner behind it is answered with no rows at all' do
    read = answer 'SELECT count(*) AS all_of_them FROM providers', nil

    assert_equal 0, read[:result].sole['all_of_them']
  end

private

  def answer(sql, provider) = Omen::Query.new(sql, Consult.new(provider_id: provider&.id)).answer

  # Said here rather than in a migration: a role is the cluster's and a policy is the table's,
  # and neither survives the schema this suite loads.
  def narrow
    ApplicationRecord.with_connection do |connection|
      quoted = connection.quote_table_name Consult.new.runs_as
      whoever = connection.quote_table_name connection.select_value('SELECT current_user')
      statements(quoted, whoever).each { |it| connection.execute it }
    end
  end

  def statements(quoted, whoever)
    [ "CREATE ROLE #{quoted} NOLOGIN",
      "GRANT #{quoted} TO #{whoever}",
      "GRANT USAGE ON SCHEMA public TO #{quoted}",
      "GRANT SELECT (id, name, created_at, updated_at) ON providers TO #{quoted}",
      'ALTER TABLE providers ENABLE ROW LEVEL SECURITY',
      "CREATE POLICY #{quoted} ON providers FOR SELECT TO #{quoted} " \
      "USING (id = NULLIF(current_setting('omen.provider_id', true), '')::bigint)", ]
  end
end
