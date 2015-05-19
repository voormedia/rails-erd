module Erd
  module Generators
    class InstallGenerator < Rails::Generators::Base
      desc "Copy rails-erd rakefiles for automatic graphic generation"
      source_root File.expand_path('../templates', __FILE__)

      # copy rake tasks
      def copy_tasks
        template "auto_generate_diagram.rake", "lib/tasks/auto_generate_diagram.rake"
      end

    end
  end
end
