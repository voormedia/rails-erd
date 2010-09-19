module RailsERD
  class Railtie < Rails::Railtie #:nodoc:
    rake_tasks do
      load "rails_erd/tasks.rake"
    end
  end
end
