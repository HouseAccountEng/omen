Rails.application.configure do
  config.enable_reloading = false
  config.eager_load = ENV['CI'].present?
  config.consider_all_requests_local = true
  config.cache_store = :memory_store
  config.active_support.deprecation = :stderr
  config.active_job.queue_adapter = :test
  config.action_controller.allow_forgery_protection = false
  config.active_record.encryption.encrypt_fixtures = true
end
