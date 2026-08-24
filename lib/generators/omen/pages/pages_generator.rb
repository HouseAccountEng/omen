require 'rails/generators/named_base'

module Omen
  module Generators
    # The least a host needs to see a reading at all: a name for one, a controller, three views
    # and a route. All of it lands in the host and is the host's from then on -- Omen has no
    # opinion about what a reading looks like. It has one about what it takes to draw one, and
    # that is the part nobody should have to learn before their first question.
    class PagesGenerator < Rails::Generators::NamedBase
      source_root File.expand_path('templates', __dir__)

      # One per action that renders, and the form the other two share.
      VIEWS = %w[ index show _form ]

      # Its own file rather than a line in the initializer, so that deleting these pages deletes
      # everything they asked for. Declared on Omen::Reading and not on the name below it,
      # because a question reaches its reading through the association: what a job is handed,
      # and so what it broadcasts as, is always the gem's own class.
      BROADCASTS = <<~RUBY
        # Refreshes every page showing a reading when its answer lands, which is long after the
        # response that asked for it went out. Written by `rails g omen:pages`, and safe to
        # delete along with the pages it was written for.
        ActiveSupport.on_load(:omen_reading) { broadcasts_refreshes }
      RUBY

      remove_argument :name
      argument :name, type: :string, default: 'Inquiry',
        desc: 'What this app calls a reading of its own'

      # Raised on rather than written over: a host that already calls something Inquiry would
      # otherwise find these pages standing where its own class used to, and quietly. The name
      # is the argument, so `omen:pages Consultation` is the whole of the fix.
      # @return [void]
      def check_collisions = class_collisions class_name, "#{plural_name.camelize}Controller"

      # @return [void]
      def copy_model = template 'model.rb', "app/models/#{singular_name}.rb"

      # @return [void]
      def copy_controller
        template 'controller.rb', "app/controllers/#{plural_name}_controller.rb"
      end

      # @return [void]
      def copy_views
        VIEWS.each do |view|
          template "#{view}.html.erb", "app/views/#{plural_name}/#{view}.html.erb"
        end
      end

      # @return [void]
      def add_route = route "resources :#{plural_name}"

      # @return [void]
      def declare_broadcasts
        return unless turbo?

        create_file 'config/initializers/omen_broadcasts.rb', BROADCASTS
      end

    private

      # Asked once, here, rather than by the pages at every render: a host either has it or has
      # no use for the line. Without one the pages still work, they only stop arriving on their
      # own, and a reload is what shows an answer.
      # @return [Boolean] whether this app has a Turbo to broadcast a refresh over.
      def turbo? = Object.const_defined? :Turbo
    end
  end
end
