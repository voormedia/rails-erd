class AppConfiguration < Configuration
  validates :name, :presence => true, :uniqueness => true
end