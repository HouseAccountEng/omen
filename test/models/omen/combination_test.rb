require 'test_helper'

# What happens to a column Claude asks to be drawn as its parts joined, because SQL could not.
class Omen::CombinationTest < ActiveSupport::TestCase
  test 'a declared combination draws its parts as one column, where the first of them stood' do
    row = { 'id' => 1, 'street' => '1 Rodeo Dr', 'rest' => 'Beverly Hills, CA' }

    assert_equal({ 'id' => 1, 'address' => '1 Rodeo Dr, Beverly Hills, CA' }, applied(row))
  end

  test 'a combination naming a header the answer has not got is ignored, and the parts stay' do
    declared = [ { 'name' => 'address', 'parts' => %w[ street state ], 'separator' => ', ' } ]

    assert_empty Omen::Combination.all declared, %w[ street city ]
  end

  # Found by exercising the feature: a street is genuinely NULL for some rows, and the join drew
  # ", Holtsville, NY 00501" -- a separator with nothing at all in front of it.
  test 'a part the row has not got leaves no separator behind it' do
    row = { 'id' => 1, 'street' => nil, 'rest' => 'Beverly Hills, CA' }

    assert_equal 'Beverly Hills, CA', applied(row)['address']
  end

  test 'a row with nothing in any of its parts draws empty, not a run of separators' do
    row = { 'id' => 1, 'street' => nil, 'rest' => '' }

    assert_equal '', applied(row)['address']
  end

private

  def applied(row)
    declared = [ { 'name' => 'address', 'parts' => %w[ street rest ], 'separator' => ', ' } ]
    Omen::Combination.all(declared, row.keys).sole.applied row
  end
end
