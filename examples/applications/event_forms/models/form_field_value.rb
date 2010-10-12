class FormFieldValue < ActiveRecord::Base
  belongs_to :form_field

  validates_presence_of :key
end
