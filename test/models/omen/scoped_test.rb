require 'test_helper'

# A reading narrowed to one owner's rows, which Postgres holds rather than the prompt: a role
# granted the columns that owner may read, and a policy admitting the rows a setting names.
class Omen::ScopedTest < ActiveSupport::TestCase
  setup { narrow }

  test 'the schema shows what the role may read, down to the column' do
    shown = Omen::Schema.new(Consult.narrowing.role).text

    assert_includes shown, 'create_table "providers"'
    assert_includes shown, 't.string "name"'
    # A credential is refused wherever it is, and this narrowing refuses a column of its own
    assert_not_includes shown, 'access_token'
    assert_not_includes shown, '"notes"'
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

  # A table reaching through another names no owner: that table's policy has already run.
  test 'a table reached through another is narrowed by the policy on the one it reaches through' do
    read = answer 'SELECT count(*) AS mine FROM homes', providers(:jobber)

    assert_equal 2, Home.count
    assert_equal 1, read[:result].sole['mine']
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

  # The whole point of the permissive policy: turning row level security on takes nothing away
  # from whoever could already read, and an empty answer is what that failure would look like.
  test 'a role nobody narrowed reads what it always read, now that the tables are turned on' do
    read = Omen::Query.new 'SELECT count(*) AS all_of_them FROM providers', Omen::Reading.new

    assert_equal Provider.count, read.answer[:result].sole['all_of_them']
  end

  test 'a role that inherits a narrowed one is narrowed with it, and the report says which' do
    ApplicationRecord.with_connection do |connection|
      assert_equal [ Consult.narrowing.role ], Omen::Bound.roles(connection).map(&:last).uniq
      assert_empty Omen::Bound.surprises(connection)

      # The membership a narrowing grants apart, granted the ordinary way instead
      connection.execute "GRANT #{Consult.narrowing.role} TO #{Omen.config.narrow_role}"

      # And the one that inherits that one is held back with it, which is the whole reason to
      # ask the database rather than to read the policies and believe them
      assert_equal %w[ omen_dummy_reader omen_inquirer ],
        Omen::Bound.surprises(connection).map(&:last).uniq.sort
    end
  end

  test 'widening takes it back off, and the role reads everything it was granted again' do
    assert_output(/Widened .* back out of #{Consult.narrowing.role}/) { Omen::Inquirer.widen }

    read = answer 'SELECT count(*) AS all_of_them FROM providers', nil

    assert_equal Provider.count, read[:result].sole['all_of_them']
  end

private

  def answer(sql, provider) = Omen::Query.new(sql, Consult.new(provider_id: provider&.id)).answer

  # Through the gem's own task rather than by hand, so what is proved here is what a host gets.
  def narrow
    ApplicationRecord.with_connection do |connection|
      whoever = connection.select_value 'SELECT current_user'
      capture_io { Omen::Inquirer.narrow connection, [ whoever ] }
    end
  end
end
