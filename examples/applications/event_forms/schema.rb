ActiveRecord::Schema.define(:version => 20100905230322) do
  create_table "event_dates", :force => true do |t|
    t.string   "date"
    t.text     "description"
    t.string   "location"
    t.date     "expiry_date"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "event_id"
  end

  create_table "events", :force => true do |t|
    t.string   "title"
    t.text     "description"
    t.text     "introduction"
    t.text     "report"
    t.string   "speaker"
    t.string   "target_audience"
    t.string   "tutors"
    t.string   "costs"
    t.string   "duration"
    t.boolean  "active"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "group_id"
  end

  create_table "form_fields", :force => true do |t|
    t.string   "name"
    t.string   "label"
    t.string   "field_type"
    t.boolean  "mandatory"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "form_id"
  end

  create_table "form_field_values", :force => true do |t|
    t.string   "key"
    t.string   "value"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "form_field_id"
  end

  create_table "forms", :force => true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "organization_id"
  end

  create_table "groups", :force => true do |t|
    t.string   "title"
    t.string   "url_slug"
    t.text     "description"
    t.boolean  "active"
    t.string   "email_subject",   :limit => 150
    t.text     "email_message"
    t.string   "email_receiver"
    t.integer  "organization_id"
    t.integer  "stylesheet_id"
    t.integer  "form_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "organizations", :force => true do |t|
    t.string   "name",                          :null => false
    t.string   "subdomain",                     :null => false
    t.string   "website"
    t.string   "domain"
    t.string   "phone"
    t.string   "signup_title",   :limit => 50
    t.string   "email_subject",  :limit => 150
    t.text     "email_message"
    t.string   "email_receiver"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "signups", :force => true do |t|
    t.string   "email"
    t.text     "serialized_fields"
    t.boolean  "confirmed"
    t.integer  "event_date_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "stylesheets", :force => true do |t|
    t.string   "name"
    t.text     "content"
    t.integer  "organization_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end
end
