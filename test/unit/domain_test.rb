require File.expand_path("../test_helper", File.dirname(__FILE__))

class DomainTest < ActiveSupport::TestCase
  # Domain ===================================================================
  test "generate should return domain" do
    assert_kind_of Domain, Domain.generate
  end

  test "name should return rails application name" do
    begin
      Object::Quux = Module.new
      Object::Quux::Application = Class.new
      Object::Rails = Struct.new(:application).new(Object::Quux::Application.new)
      assert_equal "Quux", Domain.generate.name
    ensure
      Object::Quux.send :remove_const, :Application
      Object.send :remove_const, :Quux
      Object.send :remove_const, :Rails
    end
  end

  test "name should return nil outside rails" do
    assert_nil Domain.generate.name
  end

  test "inspect should display object id only" do
    create_model "Foo", :bar => :references do
      belongs_to :bar
    end
    create_model "Bar"
    assert_match %r{#<RailsERD::Domain:.*>}, Domain.generate.inspect
  end

  # Entity processing ========================================================
  test "entity_by_name should return associated entity for given name" do
    create_model "Foo"
    assert_equal Foo, Domain.generate.entity_by_name("Foo").model
  end

  test "entities should return domain entities" do
    create_models "Foo", "Bar"
    assert_equal [Domain::Entity] * 2, Domain.generate.entities.collect(&:class)
  end

  test "entities should return all domain entities sorted by name" do
    create_models "Foo", "Bar", "Baz", "Qux"
    assert_equal [Bar, Baz, Foo, Qux], Domain.generate.entities.collect(&:model)
  end

  test "entities should include abstract entities" do
    create_model "Stronghold" do
      has_many :cannons, :as => :defensible
    end
    assert_equal ["Defensible", "Stronghold"], Domain.generate.entities.collect(&:name)
  end

  test "entities should include abstract entities only once" do
    create_model "Stronghold" do
      has_many :cannons, :as => :defensible
    end
    create_model "Galleon" do
      has_many :cannons, :as => :defensible
    end
    assert_equal ["Defensible", "Galleon", "Stronghold"], Domain.generate.entities.collect(&:name)
  end

  test "entities should include abstract models" do
    create_model "Structure" do
      self.abstract_class = true
    end
    create_model "Palace", Structure
    assert_equal ["Palace", "Structure"], Domain.generate.entities.collect(&:name)
  end

  test "entities should exclude models without a class name" do
    create_models "Foo", "Bar"
    Foo.stubs(:name).returns(nil)

    begin
      assert_equal ["Bar"], Domain.generate.entities.collect(&:name)
    ensure
      Foo.unstub(:name) # required so `reset_domain` works
    end
  end

  # Relationship processing ==================================================
  test "relationships should return empty array for empty domain" do
    assert_equal [], Domain.generate.relationships
  end

  test "relationships should return relationships in domain model" do
    create_models "Baz", "Qux"
    create_model "Foo", :bar => :references, :qux => :references do
      belongs_to :bar
      belongs_to :qux
    end
    create_model "Bar", :baz => :references do
      belongs_to :baz
    end
    assert_equal [Domain::Relationship] * 3, Domain.generate.relationships.collect(&:class)
  end

  test "relationships should count mutual relationship as one" do
    create_model "Foo", :bar => :references do
      belongs_to :bar
    end
    create_model "Bar" do
      has_many :foos
    end
    assert_equal [Domain::Relationship], Domain.generate.relationships.collect(&:class)
  end

  test "relationships should count mutual indirect relationship as one" do
    create_model "Wizard" do
      has_many :spell_masteries
      has_many :spells, :through => :spell_masteries
    end
    create_model "Spell" do
      has_many :spell_masteries
      has_many :wizards, :through => :spell_masteries
    end
    create_model "SpellMastery", :wizard => :references, :spell => :references do
      belongs_to :wizard
      belongs_to :spell
    end
    assert_equal [Domain::Relationship], Domain.generate.relationships.select(&:indirect?).collect(&:class)
  end

  test "relationships should count relationship between same models with distinct foreign key seperately" do
    skip("multiple edges between the same objects can cause segfaults in some versions of Graphviz")

    create_model "Foo", :bar => :references, :special_bar => :references do
      belongs_to :bar
    end
    create_model "Bar" do
      has_many :foos, :foreign_key => :special_bar_id
    end

    assert_equal [Domain::Relationship] * 2, Domain.generate.relationships.collect(&:class)
  end

  test "relationships should use model name first in alphabet as source for many to many relationships" do
    create_table "many_more", :many_id => :integer, :more_id => :integer
    create_model "Many" do
      has_and_belongs_to_many :more
    end
    create_model "More" do
      has_and_belongs_to_many :many
    end
    relationship = Domain.generate.relationships.first
    assert_equal ["Many", "More"], [relationship.source.name, relationship.destination.name]
  end

  test "relationships should be deterministic regardless of model order" do
    create_model "Author"
    create_model "Book", :author => :references do
      belongs_to :author
      has_many :reviews
    end
    create_model "Review", :book => :references do
      belongs_to :book
    end
    pairs = lambda do |models|
      Domain.new(models).relationships.collect { |r| [r.source.name, r.destination.name] }
    end
    models = [Author, Book, Review]
    # Order and source/destination direction must not depend on the input model order.
    assert_equal pairs.call(models), pairs.call(models.reverse)
  end

  # Specialization processing ================================================
  test "specializations should return empty array for empty domain" do
    assert_equal [], Domain.generate.specializations
  end

  test "specializations should return empty array for domain without single table inheritance" do
    create_simple_domain
    assert_equal [], Domain.generate.specializations
  end

  test "specializations should return specializations in domain model" do
    create_specialization
    assert_equal [Domain::Specialization], Domain.generate.specializations.collect(&:class)
  end

  test "specializations should return specializations of specializations in domain model" do
    create_specialization
    Object.const_set :BelgianBeer, Class.new(Beer)
    assert_equal [Domain::Specialization] * 2, Domain.generate.specializations.collect(&:class)
  end

  test "specializations should return polymorphic generalizations in domain model" do
    create_polymorphic_generalization
    assert_equal [Domain::Specialization], Domain.generate.specializations.collect(&:class)
  end

  test "specializations should return abstract generalizations in domain model" do
    create_abstract_generalization
    assert_equal [Domain::Specialization], Domain.generate.specializations.collect(&:class)
  end

  test "specializations should return polymorphic and abstract generalizations and specializations in domain model" do
    create_specialization
    create_polymorphic_generalization
    create_abstract_generalization
    assert_equal [Domain::Specialization] * 3, Domain.generate.specializations.collect(&:class)
  end

  test "specializations should return specializations in domain model once for descendants of abstract class" do
    create_model "Thing" do
      self.abstract_class = true
    end
    create_model "Beverage", Thing, :type => :string
    create_model "Beer", Beverage
    assert_equal [Domain::Specialization], Domain.generate.specializations.collect(&:class)
  end

  # Erroneous associations ===================================================
  test "relationships should omit bad has_many associations" do
    create_model "Foo" do
      has_many :flabs
    end
    assert_equal [], Domain.generate(:warn => false).relationships
  end

  test "relationships should omit bad has_many through association" do
    create_model "Foo" do
      has_many :flabs, :through => :bars
    end
    assert_equal [], Domain.generate(:warn => false).relationships
  end

  test "relationships should omit association to model outside domain" do
    create_model "Foo" do
      has_many :bars
    end
    create_model "Bar", :foo => :references
    assert_equal [], Domain.new([Foo], :warn => false).relationships
  end

  test "relationships should output a warning when a bad association is encountered" do
    create_model "Foo" do
      has_many :flabs
    end
    output = collect_stdout do
      Domain.generate.relationships
    end
    assert_match(/Ignoring invalid association :flabs on Foo/, output)
  end

  test "relationships should output a warning when an association to model outside domain is encountered" do
    create_model "Foo" do
      has_many :bars
    end
    create_model "Bar", :foo => :references
    output = collect_stdout do
      Domain.new([Foo]).relationships
    end
    assert_match(/model Bar exists, but is not included in domain/, output)
  end

  test "relationships should output a warning when an association to a non existent generalization is encountered" do
    create_model "Foo" do
      has_many :bars, :as => :foo
    end
    create_model "Bar", :foobar => :references do
      belongs_to :foo_bar, :polymorphic => true
    end
    output = collect_stdout do
      Domain.generate.relationships
    end
    assert_match(/polymorphic interface FooBar does not exist/, output)
  end

  test "relationships should not crash when exclude is present and a polymorphic association's interface does not exist" do
    create_model "Foo" do
      has_many :bars, :as => :foo
    end
    create_model "Bar", :foobar => :references do
      belongs_to :foo_bar, :polymorphic => true
    end
    output = collect_stdout do
      Domain.generate(:exclude => ["Qux"]).relationships
    end
    assert_match(/polymorphic interface FooBar does not exist/, output)
  end

  test "relationships should not warn when a bad association is encountered if warnings are disabled" do
    create_model "Foo" do
      has_many :flabs
    end
    output = collect_stdout do
      Domain.generate(:warn => false).relationships
    end
    assert_equal "", output
  end

  # Erroneous models =========================================================
  test "entities should omit bad models" do
    Object.const_set :Foo, Class.new(ActiveRecord::Base)
    assert_equal [], Domain.generate(:warn => false).entities
  end

  test "entities should output a warning when a model table does not exist" do
    Object.const_set :Foo, Class.new(ActiveRecord::Base)
    output = collect_stdout do
      Domain.generate.entities
    end
    assert_match(/Ignoring invalid model Foo \(table foos does not exist\)/, output)
  end

  test "entities should not output a warning when a Rails model table does not exist" do
    module ActionMailbox; end

    Object.const_set :InboundEmail, ActionMailbox
    output = collect_stdout do
      Domain.generate.entities
    end
    assert_equal "", output
  end

  # Pattern matching for exclude/only ==========================================
  test "matches_pattern? should match exact string" do
    domain = Domain.new([])
    assert domain.send(:matches_pattern?, "Foo", "Foo")
    refute domain.send(:matches_pattern?, "Foo", "Bar")
  end

  test "matches_pattern? should match glob pattern with asterisk" do
    domain = Domain.new([])
    assert domain.send(:matches_pattern?, "SolidQueue::*", "SolidQueue::Job")
    assert domain.send(:matches_pattern?, "SolidQueue::*", "SolidQueue::Process")
    refute domain.send(:matches_pattern?, "SolidQueue::*", "SolidCache::Entry")
  end

  test "matches_pattern? should match glob pattern without namespace separator" do
    domain = Domain.new([])
    assert domain.send(:matches_pattern?, "ActiveStorage*", "ActiveStorageBlob")
    assert domain.send(:matches_pattern?, "ActiveStorage*", "ActiveStorage::Blob")
    refute domain.send(:matches_pattern?, "ActiveStorage*", "ActionMailbox::InboundEmail")
  end

  test "matches_pattern? should match regex pattern" do
    domain = Domain.new([])
    assert domain.send(:matches_pattern?, "/^Active/", "ActiveRecord")
    assert domain.send(:matches_pattern?, "/^Active/", "ActiveStorage::Blob")
    refute domain.send(:matches_pattern?, "/^Active/", "SolidQueue::Job")
  end

  test "matches_pattern? should match regex pattern with flags" do
    domain = Domain.new([])
    assert domain.send(:matches_pattern?, "/queue/i", "SolidQueue::Job")
    refute domain.send(:matches_pattern?, "/queue/", "SolidQueue::Job")
  end

  test "excluded_model? should match glob patterns" do
    create_module_model "SolidQueue::Job"
    create_module_model "SolidQueue::Process"
    create_model "User"

    domain = Domain.generate(:exclude => ["SolidQueue::*"])

    # excluded_model? returns true for matching patterns
    assert domain.send(:excluded_model?, SolidQueue::Job)
    assert domain.send(:excluded_model?, SolidQueue::Process)
    refute domain.send(:excluded_model?, User)
  end

  test "excluded_model? should match regex patterns" do
    create_module_model "SolidQueue::Job"
    create_model "User"

    domain = Domain.generate(:exclude => ["/^Solid/"])
    assert domain.send(:excluded_model?, SolidQueue::Job)
    refute domain.send(:excluded_model?, User)
  end

  test "excluded_model? should still match exact names for backward compatibility" do
    create_model "Foo"
    create_model "Bar"

    domain = Domain.generate(:exclude => ["Foo"])
    assert domain.send(:excluded_model?, Foo)
    refute domain.send(:excluded_model?, Bar)
  end

  test "excluded_association? should match glob patterns for source model" do
    create_module_model "SolidQueue::Job" do
      has_many :executions
    end
    create_model "User"

    domain = Domain.generate(:exclude => ["SolidQueue::*"], :warn => false)
    association = SolidQueue::Job.reflect_on_association(:executions)
    assert domain.send(:excluded_association?, association)
  end

  test "excluded_association? should match glob patterns for target model" do
    create_module_model "SolidQueue::Execution"
    create_model "Task" do
      has_many :executions, :class_name => "SolidQueue::Execution"
    end

    domain = Domain.generate(:exclude => ["SolidQueue::*"], :warn => false)
    association = Task.reflect_on_association(:executions)
    assert domain.send(:excluded_association?, association)
  end
end
