# app/models/point.rb
class Point < TertiaryRecord
  self.table_name = "metadata_bet_points"
  self.ignored_columns = ["agent_id"]

  belongs_to :municipality  
  belongs_to :shopkeeper
end
