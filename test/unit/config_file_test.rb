# encoding: utf-8
require File.expand_path("../test_helper", File.dirname(__FILE__))

class ConfigFileTest < ActiveSupport::TestCase
  def normalize_value(key, value)
    RailsERD::ConfigFile.new.send(:normalize_value, key, value)
  end

  test "load_config_gile should return blank hash when USER_WIDE_CONFIG_FILE does not exist." do
    assert_equal RailsERD::ConfigFile.load, {}
  end

  test "load_config_gile should return a hash when USER_WIDE_CONFIG_FILE exists." do
    RailsERD::ConfigFile.send :remove_const, :USER_WIDE_CONFIG_FILE
    RailsERD::ConfigFile.send :const_set, :USER_WIDE_CONFIG_FILE, 
      File.expand_path("../../../examples/erdconfig.example", __FILE__)

    expected_hash = {
      :attributes     => [:content, :foreign_key, :inheritance], 
      :disconnected   => true, 
      :filename       => "erd", 
      :filetype       => :pdf, 
      :indirect       => true, 
      :inheritance    => false, 
      :markup         => true, 
      :notation       => :simple, 
      :orientation    => :horizontal, 
      :polymorphism   => false, 
      :warn           => true, 
      :title          => "sample title", 
      :exclude        => nil, 
      :only           => nil
    }
    assert_equal expected_hash, RailsERD::ConfigFile.load
  end

  test "normalize_value should return symbols in an array when key is :attributes and value is a comma-joined string." do
    assert_equal [:content, :foreign_keys], normalize_value(:attributes, "content,foreign_keys")
  end

  test "normalize_value should return symbols in an array when key is :attributes and value is strings in an array." do
    assert_equal [:content, :primary_keys], normalize_value(:attributes, ["content", "primary_keys"])
  end
end
