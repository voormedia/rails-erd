ActiveRecord::Schema.define do
  create_table "beverages", :force => true do |t|
    t.string :name, :null => false
    t.string :type
    t.string :brand
    t.integer :abv
  end
end
