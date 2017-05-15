# Extracted from https://github.com/eric/friendly_id
class Slug < ActiveRecord::Base
  belongs_to :sluggable, :polymorphic => true
end
