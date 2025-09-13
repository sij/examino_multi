# app/models/tertiary_record.rb
class TertiaryRecord < ApplicationRecord
  self.abstract_class = true

  connects_to shards: {
    sunbet:   { writing: :tertiary_sunbet },
    romar:    { writing: :tertiary_romar },
    nevada:    { writing: :tertiary_nevada },
    totalbet: { writing: :tertiary_totalbet }
  }

=begin
 def readonly?
    true
  end  
=end
end
