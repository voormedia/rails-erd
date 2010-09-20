require File.expand_path("../test_helper", File.dirname(__FILE__))

require "rails_erd/diagram"

class DiagramTest < ActiveSupport::TestCase
  def teardown
    FileUtils.rm "ERD.dot" rescue nil
  end
  
  # Diagram generation =======================================================
  test "generate should create output based on domain model" do
    create_model "Foo", :bar => :references do
      belongs_to :bar
    end
    create_model "Bar"
    RailsERD::Diagram.generate(:file_type => :dot)
    assert File.exists?("ERD.dot")
  end

  test "generate should not create output if there are no connected models" do
    RailsERD::Diagram.generate(:file_type => :dot) rescue nil
    assert !File.exists?("ERD.dot")
  end

  test "generate should abort and complain if there are no connected models" do
    message = nil
    begin
      RailsERD::Diagram.generate(:file_type => :dot)
    rescue => e
      message = e.message
    end
    assert_match /No \(connected\) entities found/, message
  end
end
