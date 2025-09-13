class SnaiModelController < ApplicationController

    def res_g1
    selected_date = params[:date]
    @items = G1Item.where(data: selected_date, bet_point_id: current_user.bet_point_id )
    end

end
