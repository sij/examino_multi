class G1DetailsController < ApplicationController
  def index

 
    @start_date = params[:start_date].presence || Date.today.beginning_of_month
    @end_date   = params[:end_date].presence   || G1Detail.maximum(:data).to_date

    #@start_date = params[:start_date].presence || Date.today.strftime("%Y-%m-%d")
    #@end_date   = params[:end_date].presence   || Date.today.strftime("%Y-%m-%d")
    @all_points = params[:all_points] == "true"
    @filter     = params[:filter]

    base_scope = if @all_points
      G1Detail.where(data: @start_date..@end_date)
    else
      G1Detail.where(bet_point_id: current_user.bet_point_id, data: @start_date..@end_date)
    end

    @g1_details = case @filter
      when "operatore"
        base_scope.where(tipologia: "operatore")
      when "selfservice"
        base_scope.where(tipologia: "SelfService")
      when "selfadvance"
        base_scope.where(tipologia: "SelfAdvance")
      when "tutti_i_selfy"
        base_scope.where(tipologia: ["SelfService", "SelfAdvance"])
      else
        base_scope
      end

    if @all_points
      @g1_details = @g1_details.order(:csmf_cod, :data)
    else
      @g1_details = @g1_details.order(:data)
    end

    # Paginazione: 50 risultati per pagina
    @g1_details = @g1_details.page(params[:page]).per(40)
  end

  def show
    @g1_detail = G1Detail.find(params[:id])
  end


  # GET /g1_details/new
  def new
    @g1_detail = G1Detail.new
  end

  # GET /g1_details/1/edit
  def edit
  end

  # POST /g1_details or /g1_details.json
  def create
    @g1_detail = G1Detail.new(g1_detail_params)

    respond_to do |format|
      if @g1_detail.save
        format.html { redirect_to @g1_detail, notice: "G1 detail was successfully created." }
        format.json { render :show, status: :created, location: @g1_detail }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @g1_detail.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /g1_details/1 or /g1_details/1.json
  def update
    respond_to do |format|
      if @g1_detail.update(g1_detail_params)
        format.html { redirect_to @g1_detail, notice: "G1 detail was successfully updated.", status: :see_other }
        format.json { render :show, status: :ok, location: @g1_detail }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @g1_detail.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /g1_details/1 or /g1_details/1.json
  def destroy
    @g1_detail.destroy!

    respond_to do |format|
      format.html { redirect_to g1_details_path, notice: "G1 detail was successfully destroyed.", status: :see_other }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_g1_detail
      @g1_detail = G1Detail.find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def g1_detail_params
      params.expect(g1_detail: [ :bet_point_id, :csmf_cod, :data, :num_term, :cod_tipo_gioco, :cod_tipo_conc, :des_gioco, :num_emesso, :impo_emesso, :num_pagato, :impo_pagato, :tipologia ])
    end
end
