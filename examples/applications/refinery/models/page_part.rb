class PagePart < ActiveRecord::Base
  belongs_to :page

  validates :title, :presence => true
end
