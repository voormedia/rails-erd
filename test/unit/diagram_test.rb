require File.expand_path("../test_helper", File.dirname(__FILE__))

class DiagramTest < ActiveSupport::TestCase
  def setup
    load "rails_erd/diagram.rb"
  end
  
  def teardown
    RailsERD.send :remove_const, :Diagram
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
end
