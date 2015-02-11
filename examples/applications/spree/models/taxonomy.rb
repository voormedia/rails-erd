class Taxonomy < ActiveRecord::Base
  has_many :taxons, :dependent => :destroy
  if ActiveRecord::VERSION::MAJOR >= 4
    has_one :root, lambda { where("parent_id is null") }, :class_name => 'Taxon'
  else
    has_one :root, :class_name => 'Taxon', :conditions => "parent_id is null"
  end
end
