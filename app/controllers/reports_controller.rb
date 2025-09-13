class ReportsController < ApplicationController

  # Esempio: app/controllers/reports_controller.rb
  def new
    @last_g1_item_date = G1Item.maximum(:data)
    # ...altro codice...
  end

  def index
    @points = Point.all.order(:code)
    @report_type = params[:report_type] || "daily"

    # Calcolo periodo in base al tipo e al parametro specifico
    case @report_type
    when "daily"
      selected_date = params[:date].present? ? Date.parse(params[:date]) : Date.current
      @period_range = selected_date.beginning_of_day..selected_date.end_of_day
      @period_label = I18n.l(selected_date, format: :long)
    when "weekly"
      if params[:week].present?
        year, week = params[:week].split("-W").map(&:to_i)
        selected_date = Date.commercial(year, week)
      else
        selected_date = Date.current
      end
      week_start = selected_date.beginning_of_week
      week_end = selected_date.end_of_week
      @period_range = week_start.beginning_of_day..week_end.end_of_day
      @period_label = "#{I18n.l(week_start, format: :long)} - #{I18n.l(week_end, format: :long)} (Settimana #{selected_date.cweek})"
    when "monthly"
      if params[:month].present?
        year, month = params[:month].split("-").map(&:to_i)
        selected_date = Date.new(year, month)
      else
        selected_date = Date.current
      end
      month_start = selected_date.beginning_of_month
      month_end = selected_date.end_of_month
      @period_range = month_start.beginning_of_day..month_end.end_of_day
      @period_label = I18n.l(month_start, format: "%B %Y")
    else
      selected_date = Date.current
      @period_range = selected_date.beginning_of_day..selected_date.end_of_day
      @period_label = I18n.l(selected_date, format: :long)
    end

    @reports = @points.map do |point|
      report_data = report_for_point(point).merge(bet_point_id: point.id)
      [point, report_data]
    end.to_h
  end

  private

  def report_for_point(point)
    items = G1Item.where(bet_point_id: point.id, data: @period_range)
    # ... (resto invariato)
    emesso_s = items.where(cod_gioco: 2, causale: "Emesso").sum(:importo) || 0
    annullato_s = items.where(cod_gioco: 2, causale: "Annullato").sum(:importo) || 0
    rimborsato_s = items.where(cod_gioco: 2, causale: "Rimborsato").sum(:importo) || 0
    venduto_sport = emesso_s - annullato_s - rimborsato_s

    pagamenti_sport = items.where(cod_gioco: 2, causale: "Pagato").sum(:importo) || 0
    saldo_gioco_sport = venduto_sport - pagamenti_sport

    emesso_v = items.where(cod_gioco: 42, causale: "Emesso").sum(:importo) || 0
    annullato_v = items.where(cod_gioco: 42, causale: "Annullato").sum(:importo) || 0
    rimborsato_v = items.where(cod_gioco: 42, causale: "Rimborsato").sum(:importo) || 0
    venduto_virtual = emesso_v - annullato_v - rimborsato_v

    pagamenti_virtual = items.where(cod_gioco: 42, causale: "Pagato").sum(:importo) || 0
    saldo_gioco_virtual = venduto_virtual - pagamenti_virtual

    saldo_cassa_totale = saldo_gioco_sport + saldo_gioco_virtual

    {
      bet_point_id: point.id,
      codice: cod_punto_by_id(point.id),
      venduto_sport: venduto_sport,
      pagamenti_sport: pagamenti_sport,
      saldo_gioco_sport: saldo_gioco_sport,
      venduto_virtual: venduto_virtual,
      pagamenti_virtual: pagamenti_virtual,
      saldo_gioco_virtual: saldo_gioco_virtual,
      saldo_cassa_totale: saldo_cassa_totale
    }
  end
end