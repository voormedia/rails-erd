require File.expand_path("../test_helper", File.dirname(__FILE__))

class RakeTaskTest < ActiveSupport::TestCase
  include ActiveSupport::Testing::Isolation

  def setup
    require "rake"
    load "rails_erd/tasks.rake"

    RailsERD.options.file_type = :dot
    RailsERD.options.suppress_warnings = true
    Rake.application.options.silent = true
  end

  def teardown
    FileUtils.rm "ERD.dot" rescue nil
    RailsERD::Diagram.send :remove_const, :Graphviz rescue nil
  end
  
  # Diagram generation =======================================================
  test "generate task should create output based on domain model" do
    create_simple_domain
    Rake::Task["erd:generate"].execute
    assert File.exists?("ERD.dot")
  end

  test "generate task should not create output if there are no connected models" do
    Rake::Task["erd:generate"].execute rescue nil
    assert !File.exists?("ERD.dot")
  end
end
