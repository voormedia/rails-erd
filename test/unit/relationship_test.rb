require File.expand_path("../test_helper", File.dirname(__FILE__))

class RelationshipTest < ActiveSupport::TestCase
  # Relationship =============================================================
  test "inspect should show source and destination" do
    create_model "Foo", :bar => :references do
      belongs_to :bar
    end
    create_model "Bar"
    domain = Domain.generate
    assert_match %r{#<RailsERD::Relationship:.* @source=Bar @destination=Foo>}, domain.relationships.first.inspect
  end
  
  test "source should return relationship source" do
    create_model "Foo", :bar => :references do
      belongs_to :bar
    end
    create_model "Bar"
    domain = Domain.generate
    assert_equal [domain.entity_for(Bar)], domain.relationships.map(&:source)
  end
  
  test "destination should return relationship destination" do
    create_model "Foo", :bar => :references do
      belongs_to :bar
    end
    create_model "Bar"
    domain = Domain.generate
    assert_equal [domain.entity_for(Foo)], domain.relationships.map(&:destination)
  end
  
  # Relationship properties ==================================================
  test "mutual should return false for one way relationship" do
    create_model "Foo", :bar => :references do
      belongs_to :bar
    end
    create_model "Bar"
    domain = Domain.generate
    assert_equal [false], domain.relationships.map(&:mutual?)
  end
  
  test "mutual should return true for mutual relationship" do
    create_model "Foo", :bar => :references do
      belongs_to :bar
    end
    create_model "Bar" do
      has_many :foos
    end
    domain = Domain.generate
    assert_equal [true], domain.relationships.map(&:mutual?)
  end
  
  test "recursive should return false for ordinary relationship" do
    create_model "Foo", :bar => :references do
      belongs_to :bar
    end
    create_model "Bar" do
      has_many :foos
    end
    domain = Domain.generate
    assert_equal [false], domain.relationships.map(&:recursive?)
  end
  
  test "recursive should return true for self referencing relationship" do
    create_model "Foo", :foo => :references do
      belongs_to :foo
    end
    domain = Domain.generate
    assert_equal [true], domain.relationships.map(&:recursive?)
  end
  
  test "indirect should return false for ordinary relationship" do
    create_model "Foo", :bar => :references do
      belongs_to :bar
    end
    create_model "Bar" do
      has_many :foos
    end
    domain = Domain.generate
    assert_equal [false], domain.relationships.map(&:indirect?)
  end
  
  test "indirect should return false for non mutual ordinary relationship" do
    create_model "Foo", :bar => :references do
      belongs_to :bar
    end
    create_model "Bar"
    domain = Domain.generate
    assert_equal [false], domain.relationships.map(&:indirect?)
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
    domain = Domain.generate
    assert_equal true, domain.relationships.find { |rel|
      rel.source.model == Bar and rel.destination.model == Baz }.indirect?
  end
  
  test "strength should return one for relationship with one association" do
    create_model "Foo", :bar => :references
    create_model "Bar" do
      has_many :foos
    end
    domain = Domain.generate
    assert_equal [1], domain.relationships.map(&:strength)
  end

  test "strength should return two for relationship with two associations" do
    create_model "Foo", :bar => :references do
      belongs_to :bar
    end
    create_model "Bar" do
      has_many :foos
    end
    domain = Domain.generate
    assert_equal [2], domain.relationships.map(&:strength)
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
    domain = Domain.generate
    assert_equal [4], domain.relationships.map(&:strength)
  end
  
  # Cardinalities ============================================================
  test "cardinality should be zero-one to zero-one for optional one to one associations" do
    create_one_to_one_assoc_domain
    assert_equal [Relationship::Cardinality.new(0..1, 0..1)], Domain.generate.relationships.map(&:cardinality)
  end

  test "cardinality should be one to one for mutually mandatory one to one associations" do
    create_one_to_one_assoc_domain
    One.class_eval do
      validates_presence_of :other
    end
    Other.class_eval do
      validates_presence_of :one
    end
    assert_equal [Relationship::Cardinality.new(1, 1)], Domain.generate.relationships.map(&:cardinality)
  end

  test "cardinality should be zero-one to zero-many for optional one to many associations" do
    create_one_to_many_assoc_domain
    assert_equal [Relationship::Cardinality.new(0..1, 0..Relationship::N)], Domain.generate.relationships.map(&:cardinality)
  end

  test "cardinality should be one to one-many for mutually mandatory one to many associations" do
    create_one_to_many_assoc_domain
    One.class_eval do
      validates_presence_of :many
    end
    Many.class_eval do
      validates_presence_of :one
    end
    assert_equal [Relationship::Cardinality.new(1, 1..Relationship::N)], Domain.generate.relationships.map(&:cardinality)
  end

  test "cardinality should be zero-one to one-n for maximised one to many associations" do
    create_one_to_many_assoc_domain
    One.class_eval do
      validates_presence_of :many

      # This kind of validation is bizarre, but we support it.
      validates_length_of :many, :maximum => 5
      validates_length_of :many, :maximum => 2  # The lowest maximum should be used.
    end
    assert_equal [Relationship::Cardinality.new(0..1, 1..2)], Domain.generate.relationships.map(&:cardinality)
  end

  test "cardinality should be zero-one to n-many for minimised one to many associations" do
    create_one_to_many_assoc_domain
    One.class_eval do
      validates_presence_of :many
      validates_length_of :many, :minimum => 2
      validates_length_of :many, :minimum => 5  # The highest minimum should be used.
    end
    assert_equal [Relationship::Cardinality.new(0..1, 5..Relationship::N)], Domain.generate.relationships.map(&:cardinality)
  end

  test "cardinality should be zero-one to n-m for limited one to many associations with single validation" do
    create_one_to_many_assoc_domain
    One.class_eval do
      validates_length_of :many, :minimum => 5, :maximum => 17
    end
    assert_equal [Relationship::Cardinality.new(0..1, 5..17)], Domain.generate.relationships.map(&:cardinality)
  end

  test "cardinality should be zero-one to n-m for limited one to many associations with multiple validations" do
    create_one_to_many_assoc_domain
    One.class_eval do
      validates_presence_of :many
      validates_length_of :many, :maximum => 17
      validates_length_of :many, :minimum => 5
      validates_length_of :many, :minimum => 2, :maximum => 28
    end
    assert_equal [Relationship::Cardinality.new(0..1, 5..17)], Domain.generate.relationships.map(&:cardinality)
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
    pending
    # create_model "Foo", :bar => :references
    # create_model "Bar" do
    #   has_one :foo
    #   has_many :foos
    # end
    # domain = Domain.generate
    # assert_equal [:one_to_many], domain.relationships.map(&:cardinality).map(&:name)
  end
  
  test "cardinality should be one to many if forward association is missing" do
    create_model "Foo", :bar => :references do
      belongs_to :bar
    end
    create_model "Bar"
    domain = Domain.generate
    assert_equal [:one_to_many], domain.relationships.map(&:cardinality).map(&:name)
  end
end
