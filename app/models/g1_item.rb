class G1Item < SecondaryRecord
  belongs_to :bet_point, class_name: "BetPointSnai", foreign_key: "bet_point_id"
  self.table_name = "g1_items"
end