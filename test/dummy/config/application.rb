require_relative 'boot'

require 'rails'
require 'action_controller/railtie'
require 'active_job/railtie'
require 'active_record/railtie'

Bundler.require(*Rails.groups)

# Stands in for the app a host installs Omen into: PostgreSQL, a read-only role, encrypted
# columns, and a db/schema.rb of its own for Claude to be shown.
module Dummy
  class Application < Rails::Application
    config.load_defaults Rails::VERSION::STRING.to_f

    config.eager_load = false
    config.time_zone = 'Eastern Time (US & Canada)'

    # Test keys, committed on purpose: this app holds no data anybody would mind reading.
    config.active_record.encryption.primary_key = 'dummy-primary-key-000000000000000'
    config.active_record.encryption.deterministic_key = 'dummy-deterministic-key-00000000'
    config.active_record.encryption.key_derivation_salt = 'dummy-key-derivation-salt-000000'
  end
end
