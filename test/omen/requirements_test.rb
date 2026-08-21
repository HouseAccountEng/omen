require 'test_helper'

class Omen::RequirementsTest < ActiveSupport::TestCase
  test 'the app this gem is tested in meets every requirement it states' do
    assert_nil Omen::Requirements.met adapter: 'postgresql', schema_format: :ruby,
      schema: Omen.config.schema
  end

  test 'an app that declares no format at all is taken to dump the one Rails dumps by default' do
    assert_nil Omen::Requirements.met adapter: 'postgresql', schema_format: nil,
      schema: Omen.config.schema
  end

  test 'an app on another adapter is refused, rather than promised what only Postgres keeps' do
    refused = assert_raises Omen::Requirements::Unmet do
      Omen::Requirements.met adapter: 'mysql2', schema_format: :ruby, schema: Omen.config.schema
    end

    assert_includes refused.message, '"mysql2"'
  end

  # A structure.sql copied to that path would be worse than none at all: the strip regexes read
  # the Ruby DSL, so they would match nothing and Claude would be shown the log of every
  # question ever asked.
  test 'an app that dumps its schema as SQL is refused, since the schema is the prompt' do
    refused = assert_raises Omen::Requirements::Unmet do
      Omen::Requirements.met adapter: 'postgresql', schema_format: :sql,
        schema: Omen.config.schema
    end

    assert_includes refused.message, 'schema_format'
  end

  test 'an app with no schema dumped is refused, rather than failing one question at a time' do
    missing = Rails.root.join 'db/nothing_of_the_sort.rb'
    refused = assert_raises Omen::Requirements::Unmet do
      Omen::Requirements.met adapter: 'postgresql', schema_format: :ruby, schema: missing
    end

    assert_includes refused.message, missing.to_s
  end
end
