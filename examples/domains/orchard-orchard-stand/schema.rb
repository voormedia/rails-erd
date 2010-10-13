ActiveRecord::Schema.define do
  create_table "orchards", :force => true do |t|
  end
  
  create_table "stands", :force => true do |t|
    t.references :orchard
  end
end
