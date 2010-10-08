ActiveRecord::Schema.define do
  create_table "galleons", :force => true do |t|
    t.string :name, :null => false
    t.integer :mast_count, :null => false
    t.date :completed_on
  end

  create_table "strongholds", :force => true do |t|
    t.string :name, :null => false
    t.string :location
    t.date :completed_on
  end

  create_table "cannons", :force => true do |t|
    t.references :defensible, :null => false
    t.integer :calibre
    t.integer :barrel_length
  end
end
