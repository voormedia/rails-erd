require File.expand_path("../test_helper", File.dirname(__FILE__))

class CardinalityTest < ActiveSupport::TestCase
  def setup
    @n = Domain::Relationship::Cardinality::N
  end

  # Cardinality ==============================================================
  test "inspect should show source and destination ranges" do
    assert_match %r{#<RailsERD::Domain::Relationship::Cardinality:.* @source_range=1\.\.1 @destination_range=1\.\.Infinity>},
      Domain::Relationship::Cardinality.new(1, 1..@n).inspect
  end

  # Cardinality construction =================================================
  test "new should return cardinality object" do
    assert_kind_of Domain::Relationship::Cardinality, Domain::Relationship::Cardinality.new(1, 1..@n)
  end

  # Cardinality properties ===================================================
  test "source_optional should return true if source range starts at zero" do
    assert_equal true, Domain::Relationship::Cardinality.new(0..1, 1).source_optional?
  end

  test "source_optional should return false if source range starts at one or more" do
    assert_equal false, Domain::Relationship::Cardinality.new(1..2, 0..1).source_optional?
  end

  test "destination_optional should return true if destination range starts at zero" do
    assert_equal true, Domain::Relationship::Cardinality.new(1, 0..1).destination_optional?
  end

  test "destination_optional should return false if destination range starts at one or more" do
    assert_equal false, Domain::Relationship::Cardinality.new(0..1, 1..2).destination_optional?
  end

  test "inverse should return inverse cardinality" do
    assert_equal Domain::Relationship::Cardinality.new(23..45, 0..15), Domain::Relationship::Cardinality.new(0..15, 23..45).inverse
  end

  # Cardinality equality =====================================================
  test "cardinalities are equal if they have the same boundaries" do
    assert_equal Domain::Relationship::Cardinality.new(1, 1..Domain::Relationship::Cardinality::N),
      Domain::Relationship::Cardinality.new(1, 1..Domain::Relationship::Cardinality::N)
  end

  test "cardinalities are not equal if they have a different source range" do
    assert_not_equal Domain::Relationship::Cardinality.new(0..1, 1..Domain::Relationship::Cardinality::N),
      Domain::Relationship::Cardinality.new(1..1, 1..Domain::Relationship::Cardinality::N)
  end

  test "cardinalities are not equal if they have a different destination range" do
    assert_not_equal Domain::Relationship::Cardinality.new(0..1, 1..Domain::Relationship::Cardinality::N),
      Domain::Relationship::Cardinality.new(0..1, 2..Domain::Relationship::Cardinality::N)
  end

  # Cardinal names ===========================================================
  test "one_to_one should return true if source and destination are exactly one" do
    assert_equal true, Domain::Relationship::Cardinality.new(1, 1).one_to_one?
  end

  test "one_to_one should return true if source and destination range are less than or equal to one" do
    assert_equal true, Domain::Relationship::Cardinality.new(0..1, 0..1).one_to_one?
  end

  test "one_to_one should return false if source range upper limit is more than one" do
    assert_equal false, Domain::Relationship::Cardinality.new(0..15, 0..1).one_to_one?
  end

  test "one_to_one should return false if destination range upper limit is more than one" do
    assert_equal false, Domain::Relationship::Cardinality.new(0..1, 0..15).one_to_one?
  end

  test "one_to_many should return true if source is exactly one and destination is higher than one" do
    assert_equal true, Domain::Relationship::Cardinality.new(1, 15).one_to_many?
  end

  test "one_to_many should return true if source is less than or equal to one and destination is higher than one" do
    assert_equal true, Domain::Relationship::Cardinality.new(0..1, 0..15).one_to_many?
  end

  test "one_to_many should return false if source range upper limit is more than one" do
    assert_equal false, Domain::Relationship::Cardinality.new(0..15, 0..15).one_to_many?
  end

  test "one_to_many should return false if destination range upper limit is one" do
    assert_equal false, Domain::Relationship::Cardinality.new(0..1, 1).one_to_many?
  end

  test "many_to_many should return true if source and destination are higher than one" do
    assert_equal true, Domain::Relationship::Cardinality.new(15, 15).many_to_many?
  end

  test "many_to_many should return true if source and destination upper limits are higher than one" do
    assert_equal true, Domain::Relationship::Cardinality.new(0..15, 0..15).many_to_many?
  end

  test "many_to_many should return false if source range upper limit is is one" do
    assert_equal false, Domain::Relationship::Cardinality.new(1, 0..15).many_to_many?
  end

  test "many_to_many should return false if destination range upper limit is one" do
    assert_equal false, Domain::Relationship::Cardinality.new(0..1, 1).many_to_many?
  end

  test "inverse of one_to_many should be many_to_one" do
    assert_equal true, Domain::Relationship::Cardinality.new(0..1, 0..@n).inverse.many_to_one?
  end

  # Cardinality order ========================================================
  test "cardinalities should be sorted in order of maniness" do
    card1 = Domain::Relationship::Cardinality.new(0..1, 1)
    card2 = Domain::Relationship::Cardinality.new(1, 1)
    card3 = Domain::Relationship::Cardinality.new(0..1, 1..3)
    card4 = Domain::Relationship::Cardinality.new(1, 1..2)
    card5 = Domain::Relationship::Cardinality.new(1, 1..@n)
    card6 = Domain::Relationship::Cardinality.new(1..5, 1..3)
    card7 = Domain::Relationship::Cardinality.new(1..2, 1..15)
    card8 = Domain::Relationship::Cardinality.new(1..15, 1..@n)
    card9 = Domain::Relationship::Cardinality.new(1..@n, 1..@n)
    assert_equal [card1, card2, card3, card4, card5, card6, card7, card8, card9],
      [card9, card5, card8, card2, card4, card7, card1, card6, card3].sort
  end
end
