class Trackback < Feedback
  belongs_to :article
  validates_presence_of :title, :excerpt, :url
end
