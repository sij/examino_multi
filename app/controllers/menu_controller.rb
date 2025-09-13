class MenuController < ApplicationController
  def determine_menu
    session[:menu_id] = params[:id].to_i
    menu = current_user.available_menu_items.find { |m| m[:id] == session[:menu_id] }
    if menu
      session[:color] = "text-#{menu[:color]}-900"
      redirect_to root_url
    else
      render plain: "Menu non trovato", status: :not_found
    end
  end
end