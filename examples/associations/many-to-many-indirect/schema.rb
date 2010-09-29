ActiveRecord::Schema.define do
  create_table "wizards", :force => true do |t|
    t.string :name, :null => false
    t.date :graduated_on
  end

  create_table "spells", :force => true do |t|
    t.string :formula, :null => false
    t.string :nickname
  end

  create_table "spell_masteries", :force => true do |t|
    t.references :wizard, :null => false
    t.references :spell, :null => false
    t.integer :strength
  end
end
