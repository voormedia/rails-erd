class Article < Content
  has_many :pings,      :dependent => :destroy, :order => "created_at ASC"
  has_many :comments,   :dependent => :destroy, :order => "created_at ASC"
  has_many :published_comments,   :class_name => "Comment", :order => "created_at ASC"
  has_many :published_trackbacks, :class_name => "Trackback", :order => "created_at ASC"
  has_many :published_feedback,   :class_name => "Feedback", :order => "created_at ASC"
  has_many :trackbacks, :dependent => :destroy, :order => "created_at ASC"
  has_many :feedback, :order => "created_at DESC"
  has_many :resources, :order => "created_at DESC",
           :class_name => "Resource", :foreign_key => 'article_id'
  has_many :categorizations
  has_many :categories, \
    :through => :categorizations, \
    :include => :categorizations, \
    :select => 'categories.*', \
    :uniq => true, \
    :order => 'categorizations.is_primary DESC'
  has_and_belongs_to_many :tags, :foreign_key => 'article_id'
  belongs_to :user
  has_many :triggers, :as => :pending_item

  validates_uniqueness_of :guid
  validates_presence_of :title
end
