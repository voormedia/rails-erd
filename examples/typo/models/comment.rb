class Comment < Feedback
  belongs_to :article
  belongs_to :user
  validates_presence_of :author, :body
end
