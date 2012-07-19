require File.expand_path("../test_helper", File.dirname(__FILE__))

class RelationshipTest < ActiveSupport::TestCase
  N = Domain::Relationship::N

  def domain_cardinalities
    Domain.generate.relationships.map(&:cardinality)
  end

  # Relationship =============================================================
  test "inspect should show source and destination" do
    create_model "Foo", :bar => :references do
      belongs_to :bar
    end
    create_model "Bar"
    assert_match %r{#<RailsERD::Domain::Relationship:.* @source=Bar @destination=Foo>}, Domain.generate.relationships.first.inspect
  end

  test "source should return relationship source" do
    create_model "Foo", :bar => :references do
      belongs_to :bar
    end
    create_model "Bar"
    domain = Domain.generate
    assert_equal [domain.entity_by_name("Bar")], domain.relationships.map(&:source)
  end

  test "destination should return relationship destination" do
    create_model "Foo", :bar => :references do
      belongs_to :bar
    end
    create_model "Bar"
    domain = Domain.generate
    assert_equal [domain.entity_by_name("Foo")], domain.relationships.map(&:destination)
  end

  test "destination should return relationship destination if specified with absolute module path" do
    create_model "Foo", :bar => :references
    create_model "Bar" do
      has_many :foos, :class_name => "::Foo"
    end
    domain = Domain.generate
    assert_equal [domain.entity_by_name("Foo")], domain.relationships.map(&:destination)
  end

  # Relationship properties ==================================================
  test "mutual should return false for one way relationship" do
    create_model "Foo", :bar => :references do
      belongs_to :bar
    end
    create_model "Bar"
    assert_equal [false], Domain.generate.relationships.map(&:mutual?)
  end

  test "mutual should return true for mutual relationship" do
    create_model "Foo", :bar => :references do
      belongs_to :bar
    end
    create_model "Bar" do
      has_many :foos
    end
    assert_equal [true], Domain.generate.relationships.map(&:mutual?)
  end

  test "mutual should return true for mutual many to many relationship" do
    create_many_to_many_assoc_domain
    assert_equal [true], Domain.generate.relationships.map(&:mutual?)
  end

  test "recursive should return false for ordinary relationship" do
    create_model "Foo", :bar => :references do
      belongs_to :bar
    end
    create_model "Bar" do
      has_many :foos
    end
    assert_equal [false], Domain.generate.relationships.map(&:recursive?)
  end

  test "recursive should return true for self referencing relationship" do
    create_model "Foo", :foo => :references do
      belongs_to :foo
    end
    assert_equal [true], Domain.generate.relationships.map(&:recursive?)
  end

  test "indirect should return false for ordinary relationship" do
    create_model "Foo", :bar => :references do
      belongs_to :bar
    end
    create_model "Bar" do
      has_many :foos
    end
    assert_equal [false], Domain.generate.relationships.map(&:indirect?)
  end

  test "indirect should return false for non mutual ordinary relationship" do
    create_model "Foo", :bar => :references do
      belongs_to :bar
    end
    create_model "Bar"
    assert_equal [false], Domain.generate.relationships.map(&:indirect?)
  end

  test "indirect should return true if relationship is a through association" do
    create_model "Foo", :baz => :references, :bar => :references do
      belongs_to :baz
      belongs_to :bar
    end
    create_model "Bar" do
      has_many :foos
      has_many :bazs, :through => :foos
    end
    create_model "Baz" do
      has_many :foos
    end
    assert_equal true, Domain.generate.relationships.find { |rel|
      rel.source.model == Bar and rel.destination.model == Baz }.indirect?
  end

  test "strength should return one for relationship with one association" do
    create_model "Foo", :bar => :references
    create_model "Bar" do
      has_many :foos
    end
    assert_equal [1], Domain.generate.relationships.map(&:strength)
  end

  test "strength should return two for relationship with two associations" do
    create_model "Foo", :bar => :references do
      belongs_to :bar
    end
    create_model "Bar" do
      has_many :foos
    end
    assert_equal [2], Domain.generate.relationships.map(&:strength)
  end

  test "strength should return number of associations that make up the relationship" do
    create_model "Foo", :bar => :references do
      belongs_to :bar
      belongs_to :special_bar, :class_name => "Bar", :foreign_key => :bar_id
    end
    create_model "Bar" do
      has_many :foos
      has_many :special_foos, :class_name => "Foo", :foreign_key => :bar_id
    end
    assert_equal [4], Domain.generate.relationships.map(&:strength)
  end

  test "strength should count polymorphic associations only once" do
    create_model "Foo", :bar => :references do
      belongs_to :bar, :polymorphic => true
    end
    create_model "Qux" do
      has_many :foos, :as => :bar
    end
    create_model "Quux" do
      has_many :foos, :as => :bar
    end
    assert_equal [1], Domain.generate.relationships.map(&:strength)
  end

  # Cardinalities ============================================================
  test "cardinality should be zero-one to zero-one for optional one to one associations" do
    create_one_to_one_assoc_domain
    assert_equal [Domain::Relationship::Cardinality.new(0..1, 0..1)], domain_cardinalities
  end

  test "cardinality should be one to one for mutually mandatory one to one associations" do
    create_one_to_one_assoc_domain
    One.class_eval do
      validates_presence_of :other
    end
    Other.class_eval do
      validates_presence_of :one
    end
    assert_equal [Domain::Relationship::Cardinality.new(1, 1)], domain_cardinalities
  end

  test "cardinality should be zero-one to zero-many for optional one to many associations" do
    create_one_to_many_assoc_domain
    assert_equal [Domain::Relationship::Cardinality.new(0..1, 0..N)], domain_cardinalities
  end

  test "cardinality should be one to zero-many for one to many associations with not null foreign key" do
    create_model "One" do
      has_many :many
    end
    create_model "Many" do
      belongs_to :one
    end
    add_column :manies, :one_id, :integer, :null => false, :default => 0
    assert_equal [Domain::Relationship::Cardinality.new(1, 0..N)], domain_cardinalities
  end

  test "cardinality should be one to one-many for mutually mandatory one to many associations" do
    create_one_to_many_assoc_domain
    One.class_eval do
      validates_presence_of :many
    end
    Many.class_eval do
      validates_presence_of :one
    end
    assert_equal [Domain::Relationship::Cardinality.new(1, 1..N)], domain_cardinalities
  end

  test "cardinality should be zero-one to one-n for maximised one to many associations" do
    create_one_to_many_assoc_domain
    One.class_eval do
      validates_presence_of :many

      # This kind of validation is bizarre, but we support it.
      validates_length_of :many, :maximum => 5
      validates_length_of :many, :maximum => 2  # The lowest maximum should be used.
    end
    assert_equal [Domain::Relationship::Cardinality.new(0..1, 1..2)], domain_cardinalities
  end

  test "cardinality should be zero-one to n-many for minimised one to many associations" do
    create_one_to_many_assoc_domain
    One.class_eval do
      validates_presence_of :many
      validates_length_of :many, :minimum => 2
      validates_length_of :many, :minimum => 5  # The highest minimum should be used.
    end
    assert_equal [Domain::Relationship::Cardinality.new(0..1, 5..N)], domain_cardinalities
  end

  test "cardinality should be zero-one to n-m for limited one to many associations with single validation" do
    create_one_to_many_assoc_domain
    One.class_eval do
      validates_length_of :many, :minimum => 5, :maximum => 17
    end
    assert_equal [Domain::Relationship::Cardinality.new(0..1, 5..17)], domain_cardinalities
  end

  test "cardinality should be zero-one to n-m for limited one to many associations with multiple validations" do
    create_one_to_many_assoc_domain
    One.class_eval do
      validates_presence_of :many
      validates_length_of :many, :maximum => 17
      validates_length_of :many, :minimum => 5
      validates_length_of :many, :minimum => 2, :maximum => 28
    end
    assert_equal [Domain::Relationship::Cardinality.new(0..1, 5..17)], domain_cardinalities
  end

  test "cardinality should be zero-many to zero-many for optional many to many associations" do
    create_many_to_many_assoc_domain
    assert_equal [Domain::Relationship::Cardinality.new(0..N, 0..N)], domain_cardinalities
  end

  test "cardinality should be one-many to one-many for mutually mandatory many to many associations" do
    create_many_to_many_assoc_domain
    Many.class_eval do
      validates_presence_of :more
    end
    More.class_eval do
      validates_presence_of :many
    end
    assert_equal [Domain::Relationship::Cardinality.new(1..N, 1..N)], domain_cardinalities
  end

  test "cardinality should be n-m to n-m for limited many to many associations with single validations" do
    create_many_to_many_assoc_domain
    Many.class_eval do
      validates_length_of :more, :minimum => 3, :maximum => 18
    end
    More.class_eval do
      validates_length_of :many, :maximum => 29, :minimum => 7
    end
    assert_equal [Domain::Relationship::Cardinality.new(7..29, 3..18)], domain_cardinalities
  end

  test "cardinality should be n-m to n-m for limited many to many associations with multiple validations" do
    create_many_to_many_assoc_domain
    Many.class_eval do
      validates_presence_of :more
      validates_length_of :more, :minimum => 3
      validates_length_of :more, :maximum => 20
      validates_length_of :more, :maximum => 33
    end
    More.class_eval do
      validates_presence_of :many
      validates_length_of :many, :minimum => 2
      validates_length_of :many, :minimum => 9
      validates_length_of :many, :maximum => 17
    end
    assert_equal [Domain::Relationship::Cardinality.new(9..17, 3..20)], domain_cardinalities
  end

  # Cardinality for non-mutual relationships =================================
  test "cardinality should be zero-one to zero-many for non mutual relationship with belongs_to association" do
    create_model "One"
    create_model "Many", :one => :references do
      belongs_to :one
    end
    assert_equal [Domain::Relationship::Cardinality.new(0..1, 0..N)], domain_cardinalities
  end

  test "cardinality should be zero-one to zero-many for non mutual relationship with has_many association" do
    create_model "One" do
      has_many :many
    end
    create_model "Many", :one => :references
    assert_equal [Domain::Relationship::Cardinality.new(0..1, 0..N)], domain_cardinalities
  end

  test "cardinality should be zero-one to zero-one for non mutual relationship with has_one association" do
    create_model "One" do
      has_one :other
    end
    create_model "Other", :one => :references
    assert_equal [Domain::Relationship::Cardinality.new(0..1, 0..1)], domain_cardinalities
  end

  test "cardinality should be zero-many to zero-many for non mutual relationship with has_and_belongs_to_many association" do
    create_table "many_more", :many_id => :integer, :more_id => :integer
    create_model "Many"
    create_model "More" do
      has_and_belongs_to_many :many
    end
    assert_equal [Domain::Relationship::Cardinality.new(0..N, 0..N)], domain_cardinalities
  end

  # Cardinality for multiple associations ====================================
  test "cardinality should be zero-one to zero-many for conflicting one to many associations" do
    create_model "CreditCard", :person => :references do
      belongs_to :person
    end
    create_model "Person" do
      has_many :credit_cards

      # A person may have a preferred card, but they are still able to have
      # many cards. The association has an infinite maximum cardinality.
      has_one :preferred_credit_card, :class_name => "CreditCard"
    end
    assert_equal [Domain::Relationship::Cardinality.new(0..1, 0..N)], domain_cardinalities
  end

  test "cardinality should be zero-one to one-many for conflicting validations in one to many associations" do
    create_model "Book", :author => :references do
      belongs_to :author
    end
    create_model "Author" do
      has_many :books
      has_many :published_books, :class_name => "Book"

      # The author certainly has books, therefore, this association has a
      # minimum cardinality of one.
      validates_presence_of :books
    end
    assert_equal [Domain::Relationship::Cardinality.new(0..1, 1..N)], domain_cardinalities
  end

  test "cardinality should be n-m to n-m for conflicting validations in one to many associations" do
    create_model "Spell", :wizard => :references do
    end
    create_model "Wizard" do
      has_many :ice_spells, :class_name => "Spell"
      has_many :fire_spells, :class_name => "Spell"

      # Well, this can make sense, based on the conditions for the associations.
      # We don't go that far yet. We ignore the lower values and opt for the
      # higher values. It'll be okay. Really... You'll never need this.
      validates_length_of :ice_spells, :in => 10..20
      validates_length_of :fire_spells, :in => 50..100
    end
    assert_equal [Domain::Relationship::Cardinality.new(0..1, 50..100)], domain_cardinalities
  end

  test "cardinality should be one to one-many for mandatory one to many associations on polymorphic interfaces" do
    create_model "Cannon", :defensible => :references do
      belongs_to :defensible, :polymorphic => true
      validates_presence_of :defensible
    end
    create_model "Stronghold" do
      has_many :cannons, :as => :defensible
      validates_presence_of :cannons
    end
    create_model "Galleon" do
      has_many :cannons, :as => :defensible
      validates_presence_of :cannons
    end
    assert_equal [Domain::Relationship::Cardinality.new(1, 1..N)], domain_cardinalities
  end

  # Cardinality classes ======================================================
  test "cardinality should be one to one for has_one associations" do
    create_one_to_one_assoc_domain
    domain = Domain.generate

    # In these test, we are liberal with the number of assertions per test.
    assert_equal [:one_to_one], domain.relationships.map(&:cardinality).map(&:name)

    assert_equal [true], domain.relationships.map(&:one_to_one?)
    assert_equal [false], domain.relationships.map(&:one_to_many?)
    assert_equal [false], domain.relationships.map(&:many_to_many?)

    assert_equal [true], domain.relationships.map(&:one_to?)
    assert_equal [false], domain.relationships.map(&:many_to?)
    assert_equal [true], domain.relationships.map(&:to_one?)
    assert_equal [false], domain.relationships.map(&:to_many?)
  end

  test "cardinality should be one to many for has_many associations" do
    create_one_to_many_assoc_domain
    domain = Domain.generate

    assert_equal [:one_to_many], domain.relationships.map(&:cardinality).map(&:name)
    assert_equal [false], domain.relationships.map(&:one_to_one?)
    assert_equal [true], domain.relationships.map(&:one_to_many?)
    assert_equal [false], domain.relationships.map(&:many_to_many?)

    assert_equal [true], domain.relationships.map(&:one_to?)
    assert_equal [false], domain.relationships.map(&:many_to?)
    assert_equal [false], domain.relationships.map(&:to_one?)
    assert_equal [true], domain.relationships.map(&:to_many?)
  end

  test "cardinality should be many to many for has_and_belongs_to_many associations" do
    create_many_to_many_assoc_domain
    domain = Domain.generate

    assert_equal [:many_to_many], domain.relationships.map(&:cardinality).map(&:name)

    assert_equal [false], domain.relationships.map(&:one_to_one?)
    assert_equal [false], domain.relationships.map(&:one_to_many?)
    assert_equal [true], domain.relationships.map(&:many_to_many?)

    assert_equal [false], domain.relationships.map(&:one_to?)
    assert_equal [true], domain.relationships.map(&:many_to?)
    assert_equal [false], domain.relationships.map(&:to_one?)
    assert_equal [true], domain.relationships.map(&:to_many?)
  end

  test "cardinality should be one to many for multiple associations with maximum cardinality of has_many" do
    create_model "Foo", :bar => :references
    create_model "Bar" do
      has_one :foo
      has_many :foos
    end
    domain = Domain.generate
    assert_equal [:one_to_many], domain.relationships.map(&:cardinality).map(&:name)
  end

  test "cardinality should be one to many if forward association is missing" do
    create_model "Foo", :bar => :references do
      belongs_to :bar
    end
    create_model "Bar"
    domain = Domain.generate
    assert_equal [:one_to_many], domain.relationships.map(&:cardinality).map(&:name)
  end

  test "cardinality should be one to many for has_many associations from generalized entity" do
    create_model "Stronghold" do
      has_many :cannons, :as => :defensible
    end
    create_model "Cannon", :defensible => :references do
      belongs_to :defensible, :polymorphic => true
    end
    domain = Domain.generate

    assert_equal [:one_to_many], domain.relationships.map(&:cardinality).map(&:name)
    assert_equal [false], domain.relationships.map(&:one_to_one?)
    assert_equal [true], domain.relationships.map(&:one_to_many?)
    assert_equal [false], domain.relationships.map(&:many_to_many?)

    assert_equal [true], domain.relationships.map(&:one_to?)
    assert_equal [false], domain.relationships.map(&:many_to?)
    assert_equal [false], domain.relationships.map(&:to_one?)
    assert_equal [true], domain.relationships.map(&:to_many?)
  end
end
