require File.expand_path("../test_helper", File.dirname(__FILE__))

class EntityTest < ActiveSupport::TestCase
  # Entity ===================================================================
  test "model should return active record model" do
    create_models "Foo"
    assert_equal Foo, Entity.new(Domain.new, Foo).model
  end
  
  test "name should return model name" do
    create_models "Foo"
    assert_equal "Foo", Entity.new(Domain.new, Foo).name
  end

  test "spaceship should sort entities by name" do
    create_models "Foo", "Bar"
    foo, bar = Entity.new(Domain.new, Foo), Entity.new(Domain.new, Bar)
    assert_equal [bar, foo], [foo, bar].sort
  end
  
  test "to_s should equal name" do
    create_models "Foo"
    assert_equal "Foo", Entity.new(Domain.new, Foo).to_s
  end

  test "inspect should show name" do
    create_models "Foo"
    assert_match %r{#<RailsERD::Entity:.* @model=Foo>}, Entity.new(Domain.new, Foo).inspect
  end

  test "relationships should return relationships for this model" do
    create_model "Foo", :bar => :references do
      belongs_to :bar
    end
    create_model "Bar", :baz => :references do
      belongs_to :baz
    end
    create_model "Baz"

    domain = Domain.generate
    foo = domain.entity_for(Foo)
    assert_equal domain.relationships.select { |r| r.destination == foo }, foo.relationships
  end
  
  test "relationships should return relationships that connect to this model" do
    create_model "Foo", :bar => :references
    create_model "Bar", :baz => :references do
      belongs_to :baz
      has_many :foos
    end
    create_model "Baz"

    domain = Domain.generate
    foo = domain.entity_for(Foo)
    assert_equal domain.relationships.select { |r| r.destination == foo }, foo.relationships
  end
  
  # Entity properties ========================================================
  test "connected should return false for unconnected entities" do
    create_models "Foo", "Bar"
    assert_equal [false, false], Domain.generate.entities.map(&:connected?)
  end

  test "connected should return true for connected entities" do
    create_model "Foo", :bar => :references do
      belongs_to :bar
    end
    create_model "Bar"
    assert_equal [true, true], Domain.generate.entities.map(&:connected?)
  end
  
  # Attribute processing =====================================================
  test "attributes should return list of attributes" do
    create_model "Bar", :some_column => :integer, :another_column => :string
    assert_equal [Attribute] * 3, Entity.new(Domain.new, Bar).attributes.collect(&:class)
  end

  test "attributes should return attributes sorted by name" do
    create_model "Bar", :some_column => :integer, :another_column => :string
    assert_equal ["another_column", "id", "some_column"], Entity.new(Domain.new, Bar).attributes.collect(&:name)
  end
end
