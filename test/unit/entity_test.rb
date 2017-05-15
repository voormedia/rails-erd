require File.expand_path("../test_helper", File.dirname(__FILE__))

class EntityTest < ActiveSupport::TestCase
  def create_entity(model)
    Domain::Entity.new(Domain.new, model.name, model)
  end

  def create_generalized_entity(name)
    Domain::Entity.new(Domain.new, name)
  end

  def create_abstract_entity(name)
    model = create_model(name) { self.abstract_class = true }
    create_entity(model)
  end

  # Entity ===================================================================
  test "model should return active record model" do
    create_models "Foo"
    assert_equal Foo, create_entity(Foo).model
  end

  test "name should return model name" do
    create_models "Foo"
    assert_equal "Foo", create_entity(Foo).name
  end

  test "spaceship should sort entities by name" do
    create_models "Foo", "Bar"
    foo, bar = create_entity(Foo), create_entity(Bar)
    assert_equal [bar, foo], [foo, bar].sort
  end

  test "to_s should equal name" do
    create_models "Foo"
    assert_equal "Foo", create_entity(Foo).to_s
  end

  test "inspect should show name" do
    create_models "Foo"
    assert_match %r{#<RailsERD::Domain::Entity:.* @model=Foo>}, create_entity(Foo).inspect
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
    foo = domain.entity_by_name("Foo")
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
    foo = domain.entity_by_name("Foo")
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

  test "disconnected should return true for unconnected entities" do
    create_models "Foo", "Bar"
    assert_equal [true, true], Domain.generate.entities.map(&:disconnected?)
  end

  test "disconnected should return false for connected entities" do
    create_model "Foo", :bar => :references do
      belongs_to :bar
    end
    create_model "Bar"
    assert_equal [false, false], Domain.generate.entities.map(&:disconnected?)
  end

  test "specialized should return false for regular entities" do
    create_model "Foo"
    assert_equal false, create_entity(Foo).specialized?
  end

  test "specialized should return false for child entities with distinct tables" do
    create_model "Foo", :type => :string
    Object.const_set :SpecialFoo, Class.new(Foo)
    SpecialFoo.class_eval do
      self.table_name = "special_foo"
    end
    create_table "special_foo", {}, true
    assert_equal false, create_entity(SpecialFoo).specialized?
  end

  test "specialized should return true for specialized entities" do
    create_model "Foo", :type => :string
    Object.const_set :SpecialFoo, Class.new(Foo)
    assert_equal true, create_entity(SpecialFoo).specialized?
  end

  test "specialized should return true for specialations of specialized entities" do
    create_model "Foo", :type => :string
    Object.const_set :SpecialFoo, Class.new(Foo)
    Object.const_set :VerySpecialFoo, Class.new(SpecialFoo)
    assert_equal true, create_entity(VerySpecialFoo).specialized?
  end

  test "virtual should return true for specialized entity" do
    create_model "Foo", :type => :string
    Object.const_set :SpecialFoo, Class.new(Foo)
    assert_equal true, create_entity(SpecialFoo).virtual?
  end

  test "generalized should return false for regular entity" do
    create_model "Concrete"
    assert_equal false, create_entity(Concrete).generalized?
  end

  test "virtual should return false for regular entity" do
    create_model "Concrete"
    assert_equal false, create_entity(Concrete).virtual?
  end

  # Attribute processing =====================================================
  test "attributes should return list of attributes" do
    create_model "Bar", :some_column => :integer, :another_column => :string
    assert_equal [Domain::Attribute] * 3, create_entity(Bar).attributes.collect(&:class)
  end

  test "attributes should return attributes sorted by name" do
    create_model "Bar", :some_column => :integer, :another_column => :string
    assert_equal ["another_column", "id", "some_column"], create_entity(Bar).attributes.collect(&:name)
  end

  # Generalized entity =======================================================
  test "model should return nil for generalized entity" do
    assert_nil create_generalized_entity("MyAbstractModel").model
  end

  test "name should return given name for generalized entity" do
    assert_equal "MyAbstractModel", create_generalized_entity("MyAbstractModel").name
  end

  test "attributes should return empty array for generalized entity" do
    assert_equal [], create_generalized_entity("MyAbstractModel").attributes
  end

  test "generalized should return true for generalized entity" do
    assert_equal true, create_generalized_entity("MyAbstractModel").generalized?
  end

  test "specialized should return false for generalized entity" do
    assert_equal false, create_generalized_entity("MyAbstractModel").specialized?
  end

  test "virtual should return true for generalized entity" do
    assert_equal true, create_generalized_entity("MyAbstractModel").virtual?
  end

  test "relationships should return relationships for generalized entity" do
    create_model "Stronghold" do
      has_many :cannons, :as => :defensible
    end
    create_model "Cannon", :defensible => :references do
      belongs_to :defensible, :polymorphic => true
    end

    domain = Domain.generate
    defensible = domain.entity_by_name("Defensible")
    assert_equal domain.relationships, defensible.relationships
  end

  # Abstract generalized entity ==============================================
  test "name should return given name for abstract generalized entity" do
    assert_equal "MyAbstractModel", create_abstract_entity("MyAbstractModel").name
  end

  test "attributes should return empty array for abstract generalized entity" do
    assert_equal [], create_abstract_entity("MyAbstractModel").attributes
  end

  test "generalized should return true for abstract generalized entity" do
    assert_equal true, create_abstract_entity("MyAbstractModel").generalized?
  end

  test "specialized should return false for abstract generalized entity" do
    assert_equal false, create_abstract_entity("MyAbstractModel").specialized?
  end

  test "virtual should return true for abstract generalized entity" do
    assert_equal true, create_abstract_entity("MyAbstractModel").virtual?
  end

  test "relationships should return relationships for abstract generalized entity" do
    create_model "Kingdom"
    create_model "Structure" do
      self.abstract_class = true
      belongs_to :kingdom
    end
    create_model "Palace", Structure, :kingdom => :references

    domain = Domain.generate
    assert_equal domain.relationships, domain.entity_by_name("Structure").relationships
  end

  # Children =================================================================
  test "children should return empty array for regular entities" do
    create_model "Foo"
    assert_equal [], create_entity(Foo).children
  end

  test "children should return inherited entities for regular entities with single table inheritance" do
    create_model "Beverage", :type => :string
    create_model "Whisky", Beverage
    create_model "Beer", Beverage
    domain = Domain.generate
    assert_equal [domain.entity_by_name("Beer"), domain.entity_by_name("Whisky")], domain.entity_by_name("Beverage").children
  end

  test "children should return inherited entities for generalized entities" do
    create_model "Stronghold" do
      has_many :cannons, :as => :defensible
    end
    create_model "Galleon" do
      has_many :cannons, :as => :defensible
    end
    create_model "Cannon", :defensible => :references do
      belongs_to :defensible, :polymorphic => true
    end
    domain = Domain.generate
    assert_equal [domain.entity_by_name("Galleon"), domain.entity_by_name("Stronghold")],
      domain.entity_by_name("Defensible").children
  end

  # Namespace ===================================================================
  test "namespace should return nil for models outside modules" do
    create_module_model "Plane"
    assert_nil create_entity(Plane).namespace
  end

  test "namespace should return the module name for single-module models" do
    create_module_model "Saw::Plane"
    assert_equal "Saw", create_entity(Saw::Plane).namespace
  end

  test "namespace should return the module path if more than one module" do
    create_module_model "Augur::Chisel::Saw::Plane"
    assert_equal "Augur::Chisel::Saw", create_entity(Augur::Chisel::Saw::Plane).namespace
  end
  
  test "namespace defaults to nil" do
    create_model "Foo"
    assert_nil create_entity(Foo).namespace
  end

  test "namespace returns appropriate modules" do
    entity = Domain::Entity.new(Domain.new, "Foo::Bar::Qux")
    assert_equal "Foo::Bar", entity.namespace
  end
end
