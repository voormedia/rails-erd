require File.expand_path("../test_helper", File.dirname(__FILE__))

class RakeTaskTest < ActiveSupport::TestCase
  include ActiveSupport::Testing::Isolation

  def setup
    require "rake"
    load "rails_erd/tasks.rake"

    RailsERD.options.filetype = :dot
    RailsERD.options.warn = false
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
  
  # Option processing ========================================================
  test "options task should ignore unknown command line options" do
    ENV["unknownoption"] = "value"
    Rake::Task["erd:options"].execute
    assert_nil RailsERD.options.unknownoption
  end

  test "options task should set known command line options" do
    ENV["filetype"] = "myfiletype"
    Rake::Task["erd:options"].execute
    assert_equal :myfiletype, RailsERD.options.filetype
  end

  test "options task should set known boolean command line options if false" do
    ENV["title"] = "false"
    Rake::Task["erd:options"].execute
    assert_equal false, RailsERD.options.title
  end

  test "options task should set known boolean command line options if true" do
    ENV["title"] = "true"
    Rake::Task["erd:options"].execute
    assert_equal true, RailsERD.options.title
  end

  test "options task should set known boolean command line options if no" do
    ENV["title"] = "no"
    Rake::Task["erd:options"].execute
    assert_equal false, RailsERD.options.title
  end

  test "options task should set known boolean command line options if yes" do
    ENV["title"] = "yes"
    Rake::Task["erd:options"].execute
    assert_equal true, RailsERD.options.title
  end
  
  test "options task should set known array command line options" do
    ENV["attributes"] = "content,timestamps"
    Rake::Task["erd:options"].execute
    assert_equal [:content, :timestamps], RailsERD.options.attributes
  end
end
