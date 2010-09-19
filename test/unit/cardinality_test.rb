require File.expand_path("../test_helper", File.dirname(__FILE__))

class CardinalityTest < ActiveSupport::TestCase
  test "cardinalities should be sorted in order of maniness" do
    assert_equal [Relationship::Cardinality::OneToOne, Relationship::Cardinality::OneToMany, Relationship::Cardinality::ManyToMany],
      [Relationship::Cardinality::OneToMany, Relationship::Cardinality::ManyToMany, Relationship::Cardinality::OneToOne].sort
  end
end
