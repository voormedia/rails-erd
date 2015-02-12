class Page < ActiveRecord::Base
  validates :title, :presence => true
  has_friendly_id :title, :use_slug => true,
                  :reserved_words => %w(index new session login logout users refinery admin images wymiframe)
  if ActiveRecord::VERSION::MAJOR >= 4
    has_many :parts,
             lambda { order(:position => :asc) },
             :class_name => "PagePart",
             :inverse_of => :page,
             :dependent => :destroy
  else
    has_many :parts,
             :class_name => "PagePart",
             :order => "position ASC",
             :inverse_of => :page,
             :dependent => :destroy
  end
end
