ActiveRecord::Schema.define do
  create_table "genres", :force => true do |t|
    t.string :name, :null => false
    t.string :description
  end
  
  create_table "films", :force => true do |t|
    t.string :title, :null => false
    t.date :release_date
    t.float :rating
  end
end
