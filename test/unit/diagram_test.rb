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

  test "generate should filter excluded polymorphic entities" do
    create_model "Cannon"
    create_model "Galleon" do
      has_many :cannons, as: :defensible
    end
    assert_equal ["Cannon", "Galleon"], retrieve_entities(polymorphism: true, exclude: :Defensible).map(&:name)
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

  test "generate should exclude relationships whose endpoints were removed by :only" do
    create_model "Author"
    create_model "Book", :author => :references do
      belongs_to :author
      has_many :reviews
    end
    create_model "Review", :book => :references do
      belongs_to :book
    end
    relationships = retrieve_relationships(:only => [:Author, :Book])
    assert_equal [Set[Author, Book]], relationships.map { |r| Set[r.source.model, r.destination.model] }
  end

  test "generate should exclude relationships to an excluded entity" do
    create_model "Author"
    create_model "Book", :author => :references do
      belongs_to :author
      has_many :reviews
    end
    create_model "Review", :book => :references do
      belongs_to :book
    end
    relationships = retrieve_relationships(:exclude => [:Review])
    assert_equal [Set[Author, Book]], relationships.map { |r| Set[r.source.model, r.destination.model] }
  end

  # Pattern matching for exclude/only ==========================================
  test "generate should filter entities matching glob pattern in exclude" do
    create_module_model "SolidQueue::Job"
    create_module_model "SolidQueue::Process"
    create_model "User"
    assert_equal [User], retrieve_entities(:exclude => ["SolidQueue::*"]).map(&:model)
  end

  test "generate should filter entities matching regex pattern in exclude" do
    create_module_model "SolidQueue::Job"
    create_model "User"
    assert_equal [User], retrieve_entities(:exclude => ["/^Solid/"]).map(&:model)
  end

  test "generate should include only entities matching glob pattern in only" do
    create_module_model "MyApp::User"
    create_module_model "MyApp::Post"
    create_model "SomeOther"
    entities = retrieve_entities(:only => ["MyApp::*"]).map(&:model)
    assert_includes entities, MyApp::User
    assert_includes entities, MyApp::Post
    refute_includes entities, SomeOther
  end

  test "generate should include only entities matching regex pattern in only" do
    create_model "AdminUser"
    create_model "AdminPost"
    create_model "GuestUser"
    entities = retrieve_entities(:only => ["/^Admin/"]).map(&:model)
    assert_includes entities, AdminUser
    assert_includes entities, AdminPost
    refute_includes entities, GuestUser
  end

  test "generate should exclude relationships when endpoint matches glob pattern" do
    create_module_model "SolidQueue::Job"
    create_model "Task", :solid_queue_job => :references do
      belongs_to :solid_queue_job, :class_name => "SolidQueue::Job"
    end
    create_model "User"
    relationships = retrieve_relationships(:exclude => ["SolidQueue::*"])
    assert_equal [], relationships
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
    assert_equal({ false => 2, true => 1 }, retrieve_relationships(:indirect => true).map(&:indirect?).tally)
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

  test "generate should not yield specializations whose entity is not part of the domain" do
    # An abstract parent whose child model has no table (e.g. ActionMailbox::Record
    # with a tableless ActionMailbox::InboundEmail): the child is excluded from the
    # domain, so the specialization resolves to a nameless Null entity. It must not
    # be yielded, otherwise generators emit an edge to a nameless entity (which is
    # invalid Mermaid output).
    Object.const_set "GhostRecord", Class.new(ActiveRecord::Base) { self.abstract_class = true }
    Object.const_set "GhostThing", Class.new(GhostRecord)

    specializations = retrieve_specializations(:inheritance => true, :polymorphism => true)
    assert_equal [], specializations.select { |s|
      s.generalized.name.to_s.empty? || s.specialized.name.to_s.empty?
    }
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

  test "generate should yield [] if attributes = false" do
    create_model "Book", :title => :string
    create_model "Page", :book => :references do
      belongs_to :book
    end
    assert_equal [], retrieve_attribute_lists(:attributes => [:false])[Book].map(&:name)
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

  test "generate should hide all attributes for a model excluded with true" do
    create_model "Book", :title => :string, :pages => :integer
    create_model "Author", :name => :string
    attribute_lists = retrieve_attribute_lists(:exclude_attributes => { "Book" => true })
    assert_equal [], attribute_lists[Book].map(&:name)
    assert_equal %w{name}, attribute_lists[Author].map(&:name)
  end

  test "generate should hide only listed attributes for a model" do
    create_model "Book", :title => :string, :subtitle => :string, :pages => :integer
    attribute_lists = retrieve_attribute_lists(:exclude_attributes => { "Book" => ["subtitle"] })
    assert_equal %w{pages title}, attribute_lists[Book].map(&:name).sort
  end

  test "generate should hide attributes for the listed model only" do
    create_model "Book", :title => :string
    create_model "Author", :name => :string
    attribute_lists = retrieve_attribute_lists(:exclude_attributes => { "Book" => ["title"] })
    assert_equal [], attribute_lists[Book].map(&:name)
    assert_equal %w{name}, attribute_lists[Author].map(&:name)
  end

  test "generate should accept exclude_attributes as a string" do
    create_model "Book", :title => :string, :subtitle => :string
    create_model "Author", :name => :string
    attribute_lists = retrieve_attribute_lists(:exclude_attributes => "Book.subtitle,Author")
    assert_equal %w{title}, attribute_lists[Book].map(&:name)
    assert_equal [], attribute_lists[Author].map(&:name)
  end

  test "normalize_exclude_attributes should split namespaced models on the first dot only" do
    assert_equal({ "Admin::User" => ["password_digest"] },
      Diagram.normalize_exclude_attributes("Admin::User.password_digest"))
  end

  test "normalize_exclude_attributes should treat a bare namespaced model as hide all" do
    assert_equal({ "Admin::User" => true },
      Diagram.normalize_exclude_attributes("Admin::User"))
  end

  test "normalize_exclude_attributes should return an empty hash for nil" do
    assert_equal({}, Diagram.normalize_exclude_attributes(nil))
  end

  test "normalize_exclude_attributes should return an empty hash for false" do
    assert_equal({}, Diagram.normalize_exclude_attributes(false))
  end

  test "normalize_exclude_attributes should ignore blank entries in a string" do
    assert_equal({ "Book" => true },
      Diagram.normalize_exclude_attributes("Book, ,"))
  end
end
