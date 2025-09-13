class SecondaryRecord < ApplicationRecord
  self.abstract_class = true
  #connects_to database: { reading: :secondary }
  connects_to database: { writing: :secondary, reading: :secondary }

 def readonly?
    true
  end  
end