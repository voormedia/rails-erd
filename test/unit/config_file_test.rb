# encoding: utf-8
require File.expand_path("../test_helper", File.dirname(__FILE__))

class ConfigFileTest < ActiveSupport::TestCase
  test "load_config_gile should return blank hash when USER_WIDE_CONFIG_FILE does not exist." do
    assert_equal RailsERD::ConfigFile.load, {}
  end

  test "load_config_gile should return a hash when USER_WIDE_CONFIG_FILE exists." do
    RailsERD::ConfigFile.send :remove_const, :USER_WIDE_CONFIG_FILE
    RailsERD::ConfigFile.send :const_set, :USER_WIDE_CONFIG_FILE, 
      File.expand_path("../../../examples/erdconfig.example", __FILE__)

    assert_equal RailsERD::ConfigFile.load, { :attributes => [:content, :foreign_key, :inheritance] }
  end
end
