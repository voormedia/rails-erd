ActiveRecord::Schema.define do
  create_table "companies", :force => true do |t|
    t.string :name, :null => false
    t.date :founded_on
  end

  create_table "orchards", :force => true do |t|
    t.references :company
    t.float :acres
    t.string :name, :null => false
    t.string :location
    t.date :planted_on, :null => false
    t.integer :revenue
  end

  create_table "picking_robots", :force => true do |t|
    t.references :orchard
    t.date :last_serviced
    t.string :model
  end

  create_table "orchards_picking_robots", :force => true, :id => false do |t|
    t.references :orchard
    t.references :picking_robot
  end

  create_table "species", :force => true do |t|
    t.string :scientific_name, :null => false
    t.string :common_name
  end

  create_table "stands", :force => true do |t|
    t.references :orchard
    t.string :address, :null => false
  end

  create_table "trees", :force => true do |t|
    t.references :orchard
    t.references :species
    t.integer :grid_number, :null => false
    t.integer :health_rating
    t.integer :produce_rating
    t.date :planted_on
  end
end
