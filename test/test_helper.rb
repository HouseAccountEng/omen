ENV['RAILS_ENV'] = 'test'

require 'simplecov'
SimpleCov.start do
  skip '/test/'
end
SimpleCov.minimum_coverage 100

require_relative 'dummy/config/environment'

# Both, so that loading the schema records the gem's own migrations as run rather than pending.
ActiveRecord::Migrator.migrations_paths = [ File.expand_path('dummy/db/migrate', __dir__),
                                            File.expand_path('../db/migrate', __dir__), ]

require 'rails/test_help'

module ActiveSupport
  class TestCase
    self.fixture_paths = [ File.expand_path('fixtures', __dir__) ]

    fixtures :all
  end
end
