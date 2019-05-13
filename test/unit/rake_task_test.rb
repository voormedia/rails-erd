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
    FileUtils.rm "erd.dot" rescue nil
  end

  define_method :create_app do
    Object::Quux = Module.new
    Object::Quux::Application = Class.new
    Object::Rails = Struct.new(:application).new(Object::Quux::Application.new)

    Rails.class_eval do
      define_method :backtrace_cleaner do
        ActiveSupport::BacktraceCleaner.new.tap do |cleaner|
          cleaner.add_filter { |line| line.sub(File.dirname(__FILE__), "test/unit") }
          cleaner.add_silencer { |line| line !~ /^test\/unit/ }
        end
      end
    end
  end

  # Diagram generation =======================================================
  test "generate task should create output based on domain model" do
    create_simple_domain

    Diagram.any_instance.expects(:save)
    Rake::Task["erd:generate"].execute
  end

  test "generate task should not create output if there are no connected models" do
    Rake::Task["erd:generate"].execute rescue nil
    assert !File.exist?("erd.dot")
  end

  test "generate task should eager load application environment" do
    eager_loaded, environment_loaded = nil
    create_app

    Rails.application.class_eval do
      define_method :eager_load! do
        eager_loaded = true
      end
    end

    Rake::Task.define_task :environment do
      environment_loaded = true
    end

    create_simple_domain

    Rake::Task["erd:generate"].invoke

    assert_equal [true, true], [eager_loaded, environment_loaded]
  end

  test "generate task should complain if active record is not loaded" do
    create_app

    Rails.application.class_eval do
      define_method :eager_load! do end
    end

    Rake::Task.define_task :environment
    Object.send :remove_const, :ActiveRecord
    message = nil

    begin
      Rake::Task["erd:generate"].invoke
    rescue => e
      message = e.message
    end
    assert_equal "Active Record was not loaded.", message
  end

  test "generate task should complain with simplified stack trace if application could not be loaded" do
    create_app
    l1, l2 = nil, nil
    Rails.application.class_eval do
      define_method :eager_load! do
        l1 = __LINE__ + 1
        raise "FooBar"
      end
    end
    Rake::Task.define_task :environment
    message = nil
    begin
      l2 = __LINE__ + 1
      Rake::Task["erd:generate"].invoke
    rescue => e
      message = e.message
    end
    assert_match(/#{Regexp.escape(<<-MSG.strip).gsub("xxx", ".*?")}/, message
Loading models failed!
Error occurred while loading application: FooBar (RuntimeError)
    test/unit/rake_task_test.rb:#{l1}:in `xxx'
    test/unit/rake_task_test.rb:#{l2}:in `xxx'
    MSG
    )
  end

  test "generate task should reraise if application could not be loaded and trace option is enabled" do
    create_app
    Rails.application.class_eval do
      define_method :eager_load! do
        raise "FooBar"
      end
    end
    Rake::Task.define_task :environment
    message = nil
    begin
      old_stderr, $stderr = $stderr, StringIO.new
      Rake.application.options.trace = true
      Rake::Task["erd:generate"].invoke
    rescue => e
      message = e.message
    ensure
      $stderr = old_stderr
    end
    assert_equal "FooBar", message
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
    assert_equal %w[content timestamps], RailsERD.options.attributes
  end

  test "options task should set known integer command line options when value is only digits" do
    ENV["only_recursion_depth"] = "2"
    Rake::Task["erd:options"].execute
    assert_equal 2, RailsERD.options.only_recursion_depth
  end

  test "options task sets known command line options as symbols when not boolean or numeric" do
    ENV["only_recursion_depth"] = "test"
    Rake::Task["erd:options"].execute
    assert_equal :test, RailsERD.options.only_recursion_depth
  end

  test "options task should set single parameter to only as array xxx" do
    ENV["only"] = "model"
    Rake::Task["erd:options"].execute
    assert_equal ["model"], RailsERD.options.only
  end
end
