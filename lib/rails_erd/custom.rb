require "rails_erd/domain"
require "rails_erd/domain"
require "rails_erd"
require "rails_erd/domain/attribute"
require "rails_erd/domain/entity"
require "rails_erd/domain/relationship"
require "rails_erd/domain/specialization"



# monkeypatch to fix strange people with edges which causes segfault in graphviz
# https://github.com/voormedia/rails-erd/issues/70
module RailsERD
  class Domain
    class Relationship
      class << self
        private

        def association_identity(association)
          Set[association_owner(association), association_target(association)]
        end
      end
    end
  end
end


module RailsERD
class Custom
  attr_accessor :classes, :reflection_keys
  
  #@class_name - Pass in the class name
  #@name of the file
  #@level - the depth you want to browse
  def initialize( class_name, file_name, level=nil )
    
    @file_name = file_name
    @class_name = class_name
    @classes = []
    @classes << class_name
    @level = level
    process
    generate
      
  end
  
  def generate
    puts "************************ classes length: #{@classes.length}"
    options = {
      :filename=>@file_name,
      :filetype=>"pdf",
      :attributes=>["foreign_keys", "primary_keys", "content"],
      :only=>@classes
    }
    begin
      byebug
      file = RailsERD::Diagram::Graphviz.create(options)
    rescue
      puts "---------------------------------Graph viz creation error"
    end
  end
  def process
    children_walk(  @class_name.constantize.reflections, 0 )
  end
  
  
  def children_walk( reflections, cur_level )
    if @level == cur_level
      return
    end
    keys = reflections.keys
    for k in keys
      p "***processing: #{k}"
      ref = reflections[ k ]
      class_name = ref.klass.name.to_s
      p class_name
      if !@classes.include? class_name
        
        p "Adding #{class_name}"
        @classes << class_name     
        
        begin
          model = class_name.constantize
          children_walk( model.reflections, cur_level + 1 )    
        rescue => e
          warn "Cannot retrieve model: #{class_name}"
        end
      end  
    end
  end
  
  def check_model_validity(model)
      model.abstract_class? or model.table_exists? or raise "table #{model.table_name} does not exist"
    rescue => e
      warn "Ignoring invalid model #{model.name} (#{e.message})"
  end
  
  end
end
