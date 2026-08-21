module Omen
  # Teaches Rails where this gem's models live, and prefixes their tables with `omen_`.
  class Engine < ::Rails::Engine
    isolate_namespace Omen

    # Read off what the app says about itself rather than by connecting, and late enough that
    # a host's own initializer has already said where its schema is.
    config.after_initialize do
      configured = ActiveRecord::Base.configurations.configs_for env_name: Rails.env,
        name: 'primary'
      Omen::Requirements.met adapter: configured&.adapter, schema: Omen.config.schema,
        schema_format: ActiveRecord.schema_format
    end
  end
end
