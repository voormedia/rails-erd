class FormField < ActiveRecord::Base
  belongs_to :form
  has_many :values, :class_name => "FormFieldValue", :foreign_key => "form_field_id"

  validates_presence_of :name
end
