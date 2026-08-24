module Omen
  # Teaches Rails where this gem's models live, and prefixes their tables with `omen_`.
  class Engine < ::Rails::Engine
    isolate_namespace Omen

    # Read off what the app declares rather than by connecting, and late enough that its own
    # initializer has already said where its schema is. The declared format rather than the
    # applied one, so nothing here depends on which after_initialize hook ran first.
    config.after_initialize do
      ActiveSupport.on_load :active_record do
        configured = ActiveRecord::Base.configurations.configs_for env_name: Rails.env,
          name: 'primary'
        Omen::Requirements.met adapter: configured&.adapter, schema: Omen.config.schema,
          schema_format: Rails.application.config.active_record.schema_format
      end
    end
  end
end
