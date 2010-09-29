ActiveRecord::Schema.define(:version => 92) do

  create_table "articles_tags", :id => false, :force => true do |t|
    t.integer "article_id"
    t.integer "tag_id"
  end

  create_table "blogs", :force => true do |t|
    t.text   "settings"
    t.string "base_url"
  end

  create_table "categories", :force => true do |t|
    t.string  "name"
    t.integer "position"
    t.string  "permalink"
    t.text    "keywords"
    t.text    "description"
    t.integer "parent_id"
  end

  add_index "categories", ["permalink"], :name => "index_categories_on_permalink"

  create_table "categorizations", :force => true do |t|
    t.integer "article_id"
    t.integer "category_id"
    t.boolean "is_primary"
  end

  create_table "contents", :force => true do |t|
    t.string   "type"
    t.string   "title"
    t.string   "author"
    t.text     "body"
    t.text     "extended"
    t.text     "excerpt"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "user_id"
    t.string   "permalink"
    t.string   "guid"
    t.integer  "text_filter_id"
    t.text     "whiteboard"
    t.string   "name"
    t.boolean  "published",      :default => false
    t.boolean  "allow_pings"
    t.boolean  "allow_comments"
    t.datetime "published_at"
    t.string   "state"
    t.integer  "parent_id"
    t.string   "password"
  end

  add_index "contents", ["published"], :name => "index_contents_on_published"
  add_index "contents", ["text_filter_id"], :name => "index_contents_on_text_filter_id"

  create_table "feedback", :force => true do |t|
    t.string   "type"
    t.string   "title"
    t.string   "author"
    t.text     "body"
    t.text     "excerpt"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "user_id"
    t.string   "guid"
    t.integer  "text_filter_id"
    t.text     "whiteboard"
    t.integer  "article_id"
    t.string   "email"
    t.string   "url"
    t.string   "ip",               :limit => 40
    t.string   "blog_name"
    t.boolean  "published",                      :default => false
    t.datetime "published_at"
    t.string   "state"
    t.boolean  "status_confirmed"
  end

  add_index "feedback", ["article_id"], :name => "index_feedback_on_article_id"
  add_index "feedback", ["text_filter_id"], :name => "index_feedback_on_text_filter_id"

  create_table "notifications", :force => true do |t|
    t.integer  "content_id"
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "pings", :force => true do |t|
    t.integer  "article_id"
    t.string   "url"
    t.datetime "created_at"
  end

  add_index "pings", ["article_id"], :name => "index_pings_on_article_id"

  create_table "profiles", :force => true do |t|
    t.string "label"
    t.string "nicename"
    t.text   "modules"
  end

  create_table "profiles_rights", :id => false, :force => true do |t|
    t.integer "profile_id"
    t.integer "right_id"
  end

  create_table "redirects", :force => true do |t|
    t.string "from_path"
    t.string "to_path"
  end

  create_table "resources", :force => true do |t|
    t.integer  "size"
    t.string   "filename"
    t.string   "mime"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "article_id"
    t.boolean  "itunes_metadata"
    t.string   "itunes_author"
    t.string   "itunes_subtitle"
    t.integer  "itunes_duration"
    t.text     "itunes_summary"
    t.string   "itunes_keywords"
    t.string   "itunes_category"
    t.boolean  "itunes_explicit"
  end

  create_table "rights", :force => true do |t|
    t.string "name"
    t.string "description"
  end

  create_table "sidebars", :force => true do |t|
    t.integer "active_position"
    t.text    "config"
    t.integer "staged_position"
    t.string  "type"
  end

  create_table "tags", :force => true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "display_name"
  end

  create_table "text_filters", :force => true do |t|
    t.string "name"
    t.string "description"
    t.string "markup"
    t.text   "filters"
    t.text   "params"
  end

  create_table "triggers", :force => true do |t|
    t.integer  "pending_item_id"
    t.string   "pending_item_type"
    t.datetime "due_at"
    t.string   "trigger_method"
  end

  create_table "users", :force => true do |t|
    t.string   "login"
    t.string   "password"
    t.text     "email"
    t.text     "name"
    t.boolean  "notify_via_email"
    t.boolean  "notify_on_new_articles"
    t.boolean  "notify_on_comments"
    t.boolean  "notify_watch_my_articles"
    t.string   "jabber"
    t.integer  "profile_id"
    t.string   "remember_token"
    t.datetime "remember_token_expires_at"
    t.string   "text_filter_id",            :default => "1"
    t.string   "editor",                    :default => "simple"
    t.string   "state",                     :default => "active"
    t.string   "firstname"
    t.string   "lastname"
    t.string   "nickname"
    t.string   "url"
    t.string   "msn"
    t.string   "aim"
    t.string   "yahoo"
    t.string   "twitter"
    t.text     "description"
    t.boolean  "show_url"
    t.boolean  "show_msn"
    t.boolean  "show_aim"
    t.boolean  "show_yahoo"
    t.boolean  "show_twitter"
    t.boolean  "show_jabber"
    t.datetime "last_connection"
  end

end
