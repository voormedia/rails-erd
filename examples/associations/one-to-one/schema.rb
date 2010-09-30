ActiveRecord::Schema.define do
  create_table "countries", :force => true do |t|
    t.string :official_name, :null => false
    t.string :common_name
    t.integer :inhabitants_count
  end

  create_table "heads_of_state", :force => true do |t|
    t.references :country, :null => false
    t.string :name, :null => false
    t.string :title
  end
end
