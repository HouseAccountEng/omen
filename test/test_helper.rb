ENV['RAILS_ENV'] = 'test'

require 'simplecov'
SimpleCov.start do
  skip '/test/'
end
SimpleCov.minimum_coverage 100

require_relative 'dummy/config/environment'
require 'rails/test_help'

module ActiveSupport
  class TestCase
    self.fixture_paths = [ File.expand_path('fixtures', __dir__) ]

    fixtures :all
  end
end
