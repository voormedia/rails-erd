class Article < Content
  if ActiveRecord::VERSION::MAJOR >= 4
    has_many :pings,  lambda { order(:created_at => :asc) }, :dependent => :destroy
    has_many :comments,  lambda { order(:created_at => :asc) },   :dependent => :destroy
    has_many :published_comments,  lambda { order(:created_at => :asc) },   :class_name => "Comment"
    has_many :published_trackbacks,  lambda { order(:created_at => :asc) }, :class_name => "Trackback"
    has_many :published_feedback,  lambda { order(:created_at => :asc) },   :class_name => "Feedback"
    has_many :trackbacks,  lambda { order(:created_at => :asc) }, :dependent => :destroy
    has_many :feedback,  lambda { order(:created_at => :asc) }
    has_many :resources,  lambda { order(:created_at => :asc) },
             :class_name => "Resource", :foreign_key => 'article_id'
    has_many :categories,  lambda { includes(:categorizations).order("categorizations.is_primary" => :desc).select("categories.*") },
      :through => :categorizations
  else
    has_many :pings,      :dependent => :destroy, :order => "created_at ASC"
    has_many :comments,   :dependent => :destroy, :order => "created_at ASC"
    has_many :published_comments,   :class_name => "Comment", :order => "created_at ASC"
    has_many :published_trackbacks, :class_name => "Trackback", :order => "created_at ASC"
    has_many :published_feedback,   :class_name => "Feedback", :order => "created_at ASC"
    has_many :trackbacks, :dependent => :destroy, :order => "created_at ASC"
    has_many :feedback, :order => "created_at DESC"
    has_many :resources, :order => "created_at DESC",
             :class_name => "Resource", :foreign_key => 'article_id'
    has_many :categories, \
      :through => :categorizations, \
      :include => :categorizations, \
      :select => 'categories.*', \
      :uniq => true, \
      :order => 'categorizations.is_primary DESC'
  end
  has_many :categorizations
  has_and_belongs_to_many :tags, :foreign_key => 'article_id'
  belongs_to :user
  has_many :triggers, :as => :pending_item

  validates_uniqueness_of :guid
  validates_presence_of :title
end
