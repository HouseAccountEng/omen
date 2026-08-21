require 'test_helper'

class Omen::InstructionsTest < ActiveSupport::TestCase
  test 'the prompt carries the schema, the classes a type column holds, and the host\'s notes' do
    said = Omen::Instructions.new.text

    assert_includes said, 'create_table "homes"'
    assert_includes said, Date.current.to_fs(:long)
    assert_includes said, '- `bookings`: `Estimate`'
    assert_includes said, 'bookings.home_id' # the app's own notes, which its schema cannot say
    Omen.tables.each { |table| assert_not_includes said, table }
  end

  test 'the prompt names every column a page reads back, and every one it will not' do
    said = Omen::Instructions.new.text

    assert_includes said, '`contacts.email`, `contacts.phone`, `contacts.surname`, `homes.street`'
    assert_includes said, '`contacts.notes`, `providers.access_token`, `providers.secret`'
  end

  # A conversion Claude wrote itself produced three defects, the last a lone AT TIME ZONE moving
  # a bucket the wrong way. The prompt names the function and leaves nothing to reason about.
  test 'a timestamp is read through the one function, with no zone left to work out' do
    said = Omen::Instructions.new.text

    assert_includes said, "#{Omen::Instructions::EASTERN}(created_at)"
    assert_not_includes said, 'AT TIME ZONE'
    assert_not_includes said, Time.zone.tzinfo.name
    assert_not_includes said, 'Eastern Time'
  end

  test 'a reply is held to one shape, and the prompt it is judged against is cached for an hour' do
    assert_equal :json_schema, Omen::Instructions.output_config[:format_][:type]
    assert_equal %w[ sql note combine ], Omen::Instructions::ANSWER[:required]

    cached = Omen::Instructions.block.sole
    assert_equal 'ephemeral', cached[:cache_control][:type]
    assert_equal '1h', cached[:cache_control][:ttl]
  end
end
