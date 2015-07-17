require File.expand_path("../test_helper", File.dirname(__FILE__))
require "rails_erd/diagram"

class DiagramTest < ActiveSupport::TestCase
  def retrieve_entities(options = {})
    klass = Class.new(Diagram)
    [].tap do |entities|
      klass.class_eval do
        each_entity do |entity, attributes|
          entities << entity
        end
      end
      klass.create(options)
    end
  end

  def retrieve_relationships(options = {})
    klass = Class.new(Diagram)
    [].tap do |relationships|
      klass.class_eval do
        each_relationship do |relationship|
          relationships << relationship
        end
      end
      klass.create(options)
    end
  end

  def retrieve_specializations(options = {})
    klass = Class.new(Diagram)
    [].tap do |specializations|
      klass.class_eval do
        each_specialization do |specialization|
          specializations << specialization
        end
      end
      klass.create(options)
    end
  end

  def retrieve_attribute_lists(options = {})
    klass = Class.new(Diagram)
    {}.tap do |attribute_lists|
      klass.class_eval do
        each_entity do |entity, attributes|
          attribute_lists[entity.model] = attributes
        end
      end
      klass.create(options)
    end
  end

  # Diagram ==================================================================
  test "domain sould return given domain" do
    domain = Object.new
    assert_same domain, Class.new(Diagram).new(domain).domain
  end

  # Diagram DSL ==============================================================
  test "create should succeed silently if called on abstract class" do
    create_simple_domain
    assert_nothing_raised do
      Diagram.create
    end
  end

  test "create should succeed if called on subclass" do
    create_simple_domain
    assert_nothing_raised do
      Class.new(Diagram).create
    end
  end

  test "create should call callbacks in instance in specific order" do
    create_simple_domain
    executed_calls = Class.new(Diagram) do
      setup do
        calls << :setup
      end

      each_entity do
        calls << :entity
      end

      each_relationship do
        calls << :relationship
      end

      save do
        calls << :save
      end

      def calls
        @calls ||= []
      end
    end.create
    assert_equal [:setup, :entity, :entity, :relationship, :save], executed_calls
  end

  test "create class method should return result of save" do
    create_simple_domain
    subclass = Class.new(Diagram) do
      save do
        "foobar"
      end
    end
    assert_equal "foobar", subclass.create
  end

  test "create should return result of save" do
    create_simple_domain
    diagram = Class.new(Diagram) do
      save do
        "foobar"
      end
    end.new(Domain.generate)
    assert_equal "foobar", diagram.create
  end

  # Entity filtering =========================================================
  test "generate should yield entities" do
    create_model "Foo"
    assert_equal [Foo], retrieve_entities.map(&:model)
  end

  test "generate should filter excluded entity" do
    create_model "Book"
    create_model "Author"
    assert_equal [Book], retrieve_entities(:exclude => [:Author]).map(&:model)
  end

  test "generate should filter excluded entities" do
    create_model "Book"
    create_model "Author"
    create_model "Editor"
    assert_equal [Book], retrieve_entities(:exclude => [:Author, :Editor]).map(&:model)
  end

  test "generate should include only specified entity" do
    create_model "Book"
    create_model "Author"
    assert_equal [Book], retrieve_entities(:only => [:Book]).map(&:model)
  end

  test "generate should include only specified entities" do
    create_model "Book"
    create_model "Author"
    create_model "Editor"
    assert_equal [Author, Editor], retrieve_entities(:only => [:Author, :Editor]).map(&:model)
  end

  test "generate should include only specified entities (With the class names as strings)" do
    create_model "Book"
    create_model "Author"
    create_model "Editor"
    assert_equal [Author, Editor], retrieve_entities(:only => ['Author', 'Editor']).map(&:model)
  end

  test "generate should filter disconnected entities if disconnected is false" do
    create_model "Book", :author => :references do
      belongs_to :author
    end
    create_model "Author"
    create_model "Table", :type => :string
    assert_equal [Author, Book], retrieve_entities(:disconnected => false).map(&:model)
  end

  test "generate should yield disconnected entities if disconnected is true" do
    create_model "Foo", :type => :string
    assert_equal [Foo], retrieve_entities(:disconnected => true).map(&:model)
  end

  test "generate should filter specialized entities" do
    create_model "Foo", :type => :string
    Object.const_set :SpecialFoo, Class.new(Foo)
    assert_equal [Foo], retrieve_entities.map(&:model)
  end

  test "generate should yield specialized entities if inheritance is true" do
    create_model "Foo", :type => :string
    Object.const_set :SpecialFoo, Class.new(Foo)
    assert_equal [Foo, SpecialFoo], retrieve_entities(:inheritance => true).map(&:model)
  end

  test "generate should yield specialized entities with distinct tables" do
    create_model "Foo"
    Object.const_set :SpecialFoo, Class.new(Foo)
    SpecialFoo.class_eval do
      self.table_name = "special_foo"
    end
    create_table "special_foo", {}, true
    assert_equal [Foo, SpecialFoo], retrieve_entities.map(&:model)
  end

  test "generate should filter generalized entities" do
    create_model "Cannon"
    create_model "Galleon" do
      has_many :cannons, :as => :defensible
    end
    assert_equal ["Cannon", "Galleon"], retrieve_entities.map(&:name)
  end

  test "generate should yield generalized entities if polymorphism is true" do
    create_model "Cannon"
    create_model "Galleon" do
      has_many :cannons, :as => :defensible
    end
    assert_equal ["Cannon", "Defensible", "Galleon"], retrieve_entities(:polymorphism => true).map(&:name)
  end

  # Relationship filtering ===================================================
  test "generate should yield relationships" do
    create_simple_domain
    assert_equal 1, retrieve_relationships.length
  end

  test "generate should yield indirect relationships if indirect is true" do
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
    assert_equal [false, false, true], retrieve_relationships(:indirect => true).map(&:indirect?)
  end

  test "generate should filter indirect relationships if indirect is false" do
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
    assert_equal [false, false], retrieve_relationships(:indirect => false).map(&:indirect?)
  end

  test "generate should yield relationships from specialized entities" do
    create_model "Foo", :bar => :references
    create_model "Bar", :type => :string
    Object.const_set :SpecialBar, Class.new(Bar)
    SpecialBar.class_eval do
      has_many :foos
    end
    assert_equal 1, retrieve_relationships.length
  end

  test "generate should yield relationships to specialized entities" do
    create_model "Foo", :type => :string, :bar => :references
    Object.const_set :SpecialFoo, Class.new(Foo)
    create_model "Bar" do
      has_many :special_foos
    end
    assert_equal 1, retrieve_relationships.length
  end

  # Specialization filtering =================================================
  test "generate should not yield specializations" do
    create_specialization
    create_polymorphic_generalization
    create_abstract_generalization
    assert_equal [], retrieve_specializations
  end

  test "generate should yield specializations but not generalizations if inheritance is true" do
    create_specialization
    create_polymorphic_generalization
    create_abstract_generalization
    assert_equal ["Beer"], retrieve_specializations(:inheritance => true).map { |s| s.specialized.name }
  end

  test "generate should yield generalizations but not specializations if polymorphism is true" do
    create_specialization
    create_polymorphic_generalization
    create_abstract_generalization
    assert_equal ["Galleon", "Palace"], retrieve_specializations(:polymorphism => true).map { |s| s.specialized.name }
  end

  test "generate should yield specializations and generalizations if polymorphism and inheritance is true" do
    create_specialization
    create_polymorphic_generalization
    create_abstract_generalization
    assert_equal ["Beer", "Galleon", "Palace"], retrieve_specializations(:inheritance => true,
      :polymorphism => true).map { |s| s.specialized.name }
  end

  # Attribute filtering ======================================================
  test "generate should yield content attributes by default" do
    create_model "Book", :title => :string, :created_at => :datetime, :author => :references do
      belongs_to :author
    end
    create_model "Author"
    assert_equal %w{title}, retrieve_attribute_lists[Book].map(&:name)
  end

  test "generate should yield primary key attributes if included" do
    create_model "Book", :title => :string
    create_model "Page", :book => :references do
      belongs_to :book
    end
    assert_equal %w{id}, retrieve_attribute_lists(:attributes => [:primary_keys])[Book].map(&:name)
  end

  test "generate should yield foreign key attributes if included" do
    create_model "Book", :author => :references do
      belongs_to :author
    end
    create_model "Author"
    assert_equal %w{author_id}, retrieve_attribute_lists(:attributes => [:foreign_keys])[Book].map(&:name)
  end

  test "generate should yield timestamp attributes if included" do
    create_model "Book", :created_at => :datetime, :created_on => :date, :updated_at => :datetime, :updated_on => :date
    create_model "Page", :book => :references do
      belongs_to :book
    end
    assert_equal %w{created_at created_on updated_at updated_on},
      retrieve_attribute_lists(:attributes => [:timestamps])[Book].map(&:name)
  end

  test "generate should yield combinations of attributes if included" do
    create_model "Book", :created_at => :datetime, :title => :string, :author => :references do
      belongs_to :author
    end
    create_model "Author"
    assert_equal %w{created_at title},
      retrieve_attribute_lists(:attributes => [:content, :timestamps])[Book].map(&:name)
  end

  test "generate should yield no attributes for specialized entities" do
    create_model "Beverage", :type => :string, :name => :string, :distillery => :string, :age => :integer
    Object.const_set :Whisky, Class.new(Beverage)
    assert_equal [], retrieve_attribute_lists(:inheritance => true)[Whisky].map(&:name)
  end
end
