class BetPointSnai < SecondaryRecord
  self.table_name = "bet_points"
  belongs_to :owner
  has_many :g1_items, foreign_key: "bet_point_id"
end