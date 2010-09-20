require File.expand_path("../test_helper", File.dirname(__FILE__))

class CardinalityTest < ActiveSupport::TestCase
  # Cardinality order ========================================================
  test "cardinalities should be sorted in order of maniness" do
    assert_equal [Relationship::Cardinality::OneToOne, Relationship::Cardinality::OneToMany, Relationship::Cardinality::ManyToMany],
      [Relationship::Cardinality::OneToMany, Relationship::Cardinality::ManyToMany, Relationship::Cardinality::OneToOne].sort
  end
  
  # Cardinality properties ===================================================
  test "one_to_one should return true for one to one cardinalities" do
    assert_equal [true, false, false], [Relationship::Cardinality::OneToOne,
      Relationship::Cardinality::OneToMany, Relationship::Cardinality::ManyToMany].map(&:one_to_one?)
  end

  test "one_to_many should return true for one to many cardinalities" do
    assert_equal [false, true, false], [Relationship::Cardinality::OneToOne,
      Relationship::Cardinality::OneToMany, Relationship::Cardinality::ManyToMany].map(&:one_to_many?)
  end

  test "many_to_many should return true for many to many cardinalities" do
    assert_equal [false, false, true], [Relationship::Cardinality::OneToOne,
      Relationship::Cardinality::OneToMany, Relationship::Cardinality::ManyToMany].map(&:many_to_many?)
  end
end
