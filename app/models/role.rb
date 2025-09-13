class Role < ApplicationRecord
	has_many :users
	
	before_destroy :ensure_not_references
	
  validates_presence_of :name
  validates_length_of :name, :maximum=>40
  validates_uniqueness_of :name
	
	private

	def ensure_not_references
		unless users.empty?
			errors.add(:base, 'User present')
			throw :abort
		end
	end

	
end
