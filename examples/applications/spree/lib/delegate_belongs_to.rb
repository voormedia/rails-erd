module DelegateBelongsTo
  module ClassMethods
    
    @@default_rejected_delegate_columns = ['created_at','created_on','updated_at','updated_on','lock_version','type','id','position','parent_id','lft','rgt']
    mattr_accessor :default_rejected_delegate_columns
        
    def delegate_belongs_to(association, *attrs)
      opts = attrs.extract_options!
      initialize_association :belongs_to, association, opts
      attrs = get_association_column_names(association) if attrs.empty?      
      attrs.concat get_association_column_names(association) if attrs.delete :defaults
      attrs.each do |attr|
        class_def attr do |*args|
          if args.empty?
            send(:delegator_for, association).send(attr)
          else
            send(:delegator_for, association).send(attr, *args)
          end
        end
        class_def "#{attr}=" do |val|
          send(:delegator_for, association).send("#{attr}=", val)
        end
      end
    end
    
    protected

    def get_association_column_names(association, without_default_rejected_delegate_columns=true)
      begin
        association_klass = reflect_on_association(association).klass    
        methods = association_klass.column_names    
        methods.reject!{|x|default_rejected_delegate_columns.include?(x.to_s)} if without_default_rejected_delegate_columns
        return methods
      rescue
        return []
      end
    end
    
    ##
    # initialize_association :belongs_to, :contact
    def initialize_association(type, association, opts={})
      raise 'Illegal or unimplemented association type.' unless [:belongs_to].include?(type.to_s.to_sym)
      send type, association, opts if reflect_on_association(association).nil?
    end
    
    private
    
    def class_def(name, method=nil, &blk)
      class_eval { method.nil? ? define_method(name, &blk) : define_method(name, method) }
    end
    
  end
  
  module InstanceMethods
    protected  
    def delegator_for(association)
      send("#{association}=", self.class.reflect_on_association(association).klass.new) if send(association).nil?
      send(association)
    end
  end
  
  def self.included(receiver)
    receiver.extend ClassMethods
    receiver.send :include, InstanceMethods
  end
end

ActiveRecord::Base.send :include, DelegateBelongsTo