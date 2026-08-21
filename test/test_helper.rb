ENV['RAILS_ENV'] = 'test'

require 'simplecov'
SimpleCov.start do
  skip '/test/'
  # Named rather than left to whatever got loaded: a file nothing exercises is the point
  cover '{app,lib}/**/*.rb'
  # Read by the gemspec, which Bundler evaluates before this line runs, and it holds a constant
  skip 'lib/omen/version.rb'
  # What the generator writes into a host, which is prose here and Ruby only once it lands
  skip '/templates/'
end
SimpleCov.minimum_coverage 100

require_relative 'dummy/config/environment'

# Both, so that loading the schema records the gem's own migrations as run rather than pending.
ActiveRecord::Migrator.migrations_paths = [ File.expand_path('dummy/db/migrate', __dir__),
                                            File.expand_path('../db/migrate', __dir__), ]

require 'rails/test_help'
require 'webmock/minitest'

require 'omen/stubs'

module ActiveSupport
  class TestCase
    include ActiveJob::TestHelper, Omen::Stubs

    self.fixture_paths = [ File.expand_path('fixtures', __dir__) ]

    fixtures :all
  end
end
