class Version < ActiveRecord::Base
  belongs_to :rubygem
  has_many :dependencies, :dependent => :destroy
end
