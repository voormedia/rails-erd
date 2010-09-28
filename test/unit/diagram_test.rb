require File.expand_path("../test_helper", File.dirname(__FILE__))

class DiagramTest < ActiveSupport::TestCase
  def setup
    load "rails_erd/diagram.rb"
  end
  
  def teardown
    RailsERD.send :remove_const, :Diagram
  end
  
  def retrieve_relationships(klass, options = {})
    [].tap do |relationships|
      klass.class_eval do
        define_method :process_relationship do |relationship|
          relationships << relationship
        end
      end
      klass.create(options)
    end
  end
  
  # Diagram ==================================================================
  test "create class method should return result of save" do
    create_simple_domain
    subclass = Class.new(Diagram) do
      def save
        "foobar"
      end
    end
    assert_equal "foobar", subclass.create
  end

  test "create should return result of save" do
    create_simple_domain
    diagram = Class.new(Diagram) do
      def save
        "foobar"
      end
    end.new(Domain.generate)
    assert_equal "foobar", diagram.create
  end
  
  test "domain sould return given domain" do
    domain = Object.new
    assert_same domain, Class.new(Diagram).new(domain).domain
  end

  # Diagram abstractness =====================================================
  test "create should succeed silently if called on abstract class" do
    create_simple_domain
    assert_nothing_raised do
      Diagram.create
    end
  end

  test "create should succeed if called on class that implements process_entity and process_relationship" do
    create_simple_domain
    assert_nothing_raised do
      Class.new(Diagram) do
        def process_entity(*args)
        end
        def process_relationship(*args)
        end
      end.create
    end
  end
  
  # Diagram filtering ========================================================
  test "generate should yield relationships" do
    create_simple_domain
    assert_equal 1, retrieve_relationships(Class.new(Diagram)).length
  end

  test "generate should yield indirect relationships if exclude_indirect is false" do
    create_model "Foo" do
      has_many :bazs
      has_many :bars
    end
    create_model "Bar", :foo => :references do
      belongs_to :foo
      has_many :bazs, :through => :foo
    end
    create_model "Baz", :foo => :references do
      belongs_to :foo
    end
    assert_equal [false, false, true], retrieve_relationships(Class.new(Diagram), :exclude_indirect => false).map(&:indirect?)
  end
  
  test "generate should filter indirect relationships if exclude_indirect is true" do
    create_model "Foo" do
      has_many :bazs
      has_many :bars
    end
    create_model "Bar", :foo => :references do
      belongs_to :foo
      has_many :bazs, :through => :foo
    end
    create_model "Baz", :foo => :references do
      belongs_to :foo
    end
    assert_equal [false, false], retrieve_relationships(Class.new(Diagram), :exclude_indirect => true).map(&:indirect?)
  end
end
