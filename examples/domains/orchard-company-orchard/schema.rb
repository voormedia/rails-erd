ActiveRecord::Schema.define do
  create_table "companies", :force => true do |t|
  end
  
  create_table "orchards", :force => true do |t|
    t.references :company
  end
end
