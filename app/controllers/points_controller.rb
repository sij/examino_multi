class PointsController < ApplicationController
  # GET /points
  def index
    #@points = Point.select(:id, :code, :municipality_id, :tipo_ter_1, :tipo_ter_2, :tipo_ter_3, :prenotatori).all.order(:code)
    #@points = Point.joins(:municipality).order('municipality.comune ASC')
    @points = Point.includes(:municipality).references(:municipality).order('municipality.comune ASC')



  end

  # GET /points/:id
  def show
    @point = Point.select(:id, :code, :municipality_id, :shopkeeper_id).find(params[:id])
  end

  # Nessuna azione per new, create, edit, update, destroy
end