require 'rails/generators/active_record'

module Omen
  module Generators
    # Everything installing this gem writes into a host: three migrations and one initializer.
    # Not the roles or the database function, which are a rake task, because a copy of those
    # would drift from what the gem goes on to expect and nothing would detect it.
    class InstallGenerator < Rails::Generators::Base
      include ActiveRecord::Generators::Migration

      # Both, since the migrations are shipped where they run from rather than as templates.
      # @return [Array<String>] where a file being copied is looked for.
      def self.source_paths
        [ File.expand_path('templates', __dir__), Omen::Engine.root.join('db/migrate').to_s ]
      end

      # Copied rather than read off the gem, so the host owns the files and their timestamps.
      # @return [void]
      def copy_migrations
        Dir.children(Omen::Engine.root.join('db/migrate')).sort.each do |name|
          migration_template name, "db/migrate/#{name.split('_', 2).last}"
        end
      end

      # @return [void]
      def copy_initializer
        template 'omen.rb', 'config/initializers/omen.rb'
      end
    end
  end
end
