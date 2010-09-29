ActiveRecord::Schema.define do
  create_table "users", :force => true do |t|
    t.string :handle, :null => false, :unique => true
    t.string :encrypted_password, :limit => 160
  end

  create_table "profiles", :force => true do |t|
    t.references :user, :null => false
    t.string :first_name
    t.string :last_name
    t.text :biography
  end
end
