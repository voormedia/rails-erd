ActiveRecord::Schema.define do
  create_table "barricades", :force => true do |t|
    t.string :name, :null => false
    t.string :location
    t.boolean :upheld, :null => false
  end

  create_table "strongholds", :force => true do |t|
    t.string :name, :null => false
    t.string :location
    t.date :completed_on
  end

  create_table "soldiers", :force => true do |t|
    t.references :defensible, :null => false
    t.integer :health_rating, :null => false
    t.integer :armor_rating
  end
end
