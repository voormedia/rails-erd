require File.expand_path("../test_helper", File.dirname(__FILE__))

class SpecializationTest < ActiveSupport::TestCase
  # Specialization ===========================================================
  test "inspect should show source and destination" do
    create_specialization
    domain = Domain.generate
    assert_match %r{#<RailsERD::Domain::Specialization:.* @generalized=Beverage @specialized=Beer>},
      Domain::Specialization.new(domain, domain.entity_by_name("Beverage"), domain.entity_by_name("Beer")).inspect
  end

  test "generalized should return source entity" do
    create_specialization
    domain = Domain.generate
    assert_equal domain.entity_by_name("Beverage"),
      Domain::Specialization.new(domain, domain.entity_by_name("Beverage"), domain.entity_by_name("Beer")).generalized
  end

  test "specialized should return destination entity" do
    create_specialization
    domain = Domain.generate
    assert_equal domain.entity_by_name("Beer"),
      Domain::Specialization.new(domain, domain.entity_by_name("Beverage"), domain.entity_by_name("Beer")).specialized
  end

  # Specialization properties ================================================
  test "inheritance should be true for inheritance specializations" do
    create_specialization
    assert_equal [true], Domain.generate.specializations.map(&:inheritance?)
  end

  test "polymorphic should be false for inheritance specializations" do
    create_specialization
    assert_equal [false], Domain.generate.specializations.map(&:polymorphic?)
  end

  test "inheritance should be false for polymorphic specializations" do
    create_polymorphic_generalization
    assert_equal [false], Domain.generate.specializations.map(&:inheritance?)
  end

  test "polymorphic should be true for polymorphic specializations" do
    create_polymorphic_generalization
    assert_equal [true], Domain.generate.specializations.map(&:polymorphic?)
  end

  test "inheritance should be false for abstract specializations" do
    create_abstract_generalization
    assert_equal [false], Domain.generate.specializations.map(&:inheritance?)
  end

  test "polymorphic should be true for abstract specializations" do
    create_abstract_generalization
    assert_equal [true], Domain.generate.specializations.map(&:polymorphic?)
  end

  test "inheritance should be false for polymorphic specializations to specialized entities" do
    create_model "Cannon"
    create_model "Ship", :type => :string
    create_model "Galleon", Ship do
      has_many :cannons, :as => :defensible
    end
    domain = Domain.generate
    assert_equal false, domain.specializations.find { |s|
      s.generalized == domain.entity_by_name("Defensible") }.inheritance?
  end
end
