ActiveRecord::Schema.define do
  create_table "photographs" do |t|
    t.decimal  :aperture
    t.binary   :data,        :null => false
    t.text     :description,                 :limit => 512
    t.string   :filename,    :null => false, :limit => 64
    t.boolean  :flash
    t.integer  :iso
    t.float    :shutter_speed
    t.datetime :taken_at,    :null => false
  end
end
