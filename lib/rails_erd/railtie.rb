module RailsERD
  # Rails ERD integrates with Rails 3. If you add it to your +Gemfile+, you
  # will gain a Rake task called +erd+, which you can use to generate diagrams
  # of your domain model.
  class Railtie < Rails::Railtie
    rake_tasks do
      load "rails_erd/tasks.rake"
    end
  end
end
