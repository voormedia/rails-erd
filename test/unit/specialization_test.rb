require File.expand_path("../test_helper", File.dirname(__FILE__))

class SpecializationTest < ActiveSupport::TestCase
  # Specialization ===========================================================
  test "inspect should show source and destination" do
    create_specialization
    assert_match %r{#<RailsERD::Domain::Specialization:.* @generalized=Beverage @specialized=Beer>},
      Domain::Specialization.new(Domain.generate, Beer).inspect
  end
  
  test "generalized should return source entity" do
    create_specialization
    domain = Domain.generate
    assert_equal domain.entity_for(Beverage), Domain::Specialization.new(domain, Beer).generalized
  end

  test "specialized should return source entity" do
    create_specialization
    domain = Domain.generate
    assert_equal domain.entity_for(Beer), Domain::Specialization.new(domain, Beer).specialized
  end
end
