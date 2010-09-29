ActiveRecord::Schema.define do
  create_table "domains", :force => true do |t|
    t.string :name
  end

  create_table "entities", :force => true do |t|
    t.references :domain
    t.string :name, :null => false
  end

  create_table "relationships", :force => true do |t|
    t.references :source_entity, :null => false
    t.references :destination_entity, :null => false
    t.integer :strength, :null => false
    t.boolean :indirect
    t.boolean :mutual
  end
  
  create_table "attributes", :force => true do |t|
    t.references :entity
    t.string :name, :null => false
    t.string :type, :null => false
    t.boolean :mandatory, :null => false
  end
  
  create_table "cardinalities", :force => true do |t|
    t.references :relationship
    t.integer :source_minimum, :null => false
    t.integer :source_maximum
    t.integer :destination_minimum, :null => false
    t.integer :destination_maximum
  end
end
