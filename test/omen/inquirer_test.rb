require 'test_helper'

# The role a reading's statement runs as, and the function it reads a timestamp through.
class Omen::InquirerTest < ActiveSupport::TestCase
  test 'the task a host runs makes the role and the function, and runs again over both' do
    2.times { assert_output(/Granted SELECT on omen_dummy_test/) { Omen::Inquirer.grant } }
  end

  test 'the role is refused the tables a reading is kept in, and granted to whoever reads' do
    ApplicationRecord.with_connection do |connection|
      said = Omen::Inquirer.statements connection, %w[ somebody ]

      Omen.tables.each do |table|
        assert_includes said, %(REVOKE SELECT ON "#{table}" FROM "omen_inquirer")
      end
      assert_includes said, 'GRANT "omen_inquirer" TO "somebody"'
      assert_includes said, 'ALTER ROLE "omen_inquirer" WITH NOLOGIN ' \
                            "#{Omen::Inquirer::ATTRIBUTES}"
      assert(said.any? { |statement| statement.include? Omen::Eastern::ZONE })
    end
  end

  # A managed database never grants CREATEROLE, and a deploy has to finish anyway, having said
  # what somebody has to make by hand.
  test 'a database that will not make the role is warned about rather than raised on' do
    Omen.config.narrow_role = 'pg_reserved_for_postgres' # a name no database will hand over

    said = on_its_own_connection { |connection| capture_io { Omen::Inquirer.grant_on connection } }

    assert_match(/Could not make/, said.last)
  ensure
    Omen.config.narrow_role = 'omen_inquirer'
  end

  # Installation step one leaves a host with no reading role declared, and that is a message
  # rather than a failure: nothing reads through the narrow role until there is one.
  test 'the user a host reads through is discovered, and says so where there is none yet' do
    assert_not_nil Omen::Inquirer.reader

    Omen.config.reading_role = :nowhere_at_all
    assert_nil Omen::Inquirer.reader
  ensure
    Omen.config.reading_role = :reading
  end

private

  # Kept off the connection this test runs in, whose transaction a refused statement would abort.
  def on_its_own_connection(&)
    config = ActiveRecord::Base.configurations.configs_for env_name: 'test', name: 'primary'
    ActiveRecord::Tasks::DatabaseTasks.with_temporary_connection config, &
  end
end
