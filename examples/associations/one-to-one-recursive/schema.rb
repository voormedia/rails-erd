ActiveRecord::Schema.define do
  create_table "emperors", :force => true do |t|
    t.string :name, :null => false
    t.boolean :murdered
    t.references :predecessor
    t.date :reigned_from
    t.date :reigned_until
  end
end
