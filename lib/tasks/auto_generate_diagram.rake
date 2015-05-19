namespace :db do
  task :migrate do
    ERDGraph::Migration.update_model
  end

  namespace :migrate do
    [:change, :up, :down, :reset, :redo].each do |t|
      task t do
        ERDGraph::Migration.update_model
      end
    end
  end
end

module ERDGraph
  class Migration
    def self.update_model
      Rake::Task['erd'].invoke
    end
  end
end
