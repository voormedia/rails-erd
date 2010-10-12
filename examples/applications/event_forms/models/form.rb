class Form < ActiveRecord::Base
  belongs_to :organization
  has_many :groups
  has_many :fields, :class_name => "FormField", :foreign_key => "form_id"

  validates_presence_of :name
end
