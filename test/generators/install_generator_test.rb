require 'test_helper'
require 'rails/generators/test_case'
require 'generators/omen/install/install_generator'

class Omen::Generators::InstallGeneratorTest < Rails::Generators::TestCase
  tests Omen::Generators::InstallGenerator
  destination Rails.root.join 'tmp/generated'
  setup :prepare_destination

  test 'an install hands the host the three migrations, under timestamps of its own' do
    run_generator

    assert_migration 'db/migrate/create_omen_readings.rb', /create_enum :omen_status/
    assert_migration 'db/migrate/create_omen_questions.rb', /to_table: :omen_readings/
    assert_migration 'db/migrate/create_omen_answers.rb', /index: { unique: true }/
  end

  test 'an install writes an initializer naming every setting and demanding none of them' do
    run_generator

    assert_file 'config/initializers/omen.rb' do |written|
      assert_match(/Omen\.configure/, written)
      assert_match(/# config\.narrow_role = 'omen_inquirer'/, written)
      assert_match(%r{# config\.schema_path = 'db/schema\.rb'}, written)
    end
  end
end
