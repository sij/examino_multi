class HomeController < ApplicationController

  def about
    # Prendo la configurazione dei database per l'ambiente corrente
    db_config = Rails.configuration.database_configuration[Rails.env]

    # Costruisco un array di hash con ruolo e nome database
    @databases = db_config.map do |role, config|
      {
        role: role,
        database: config["database"],
        replica: config["replica"] || false
      }
    end
  end

  # GET /home/select_point
  #def select_point
   # @bet_points = Point.includes(:municipality).all.order(:code)
  #end

  def select_point
  @bet_points = Point
    .includes(:municipality)
    .references(:municipalities)
    .joins(:municipality)
    .order('municipalities.comune ASC, metadata_bet_points.code ASC')
  end

  # POST /home/assign_point
  def assign_point
    bet_point = Point.find(params[:bet_point_id])
    current_user.update(bet_point_id: bet_point.id)
    redirect_to root_path, notice: "Punto assegnato correttamente! #{current_user.bet_point_id} #{bet_point.id}"
  end

  def self_advances
    @self_advances = SelfAdvance.order(:num_term)
  end

end

