class DataAnalysisController < ApplicationController

def input_analyze
  @start_date = Date.today.beginning_of_month
  @end_date = G1Detail.maximum(:data) 
end

def res_analyze
  @num_terminali = Point.find(current_user.bet_point_id)
  @start_date = params[:start_date].presence&.to_date || Date.today.beginning_of_month
  @end_date   = params[:end_date].presence&.to_date   || Date.today
  # Controllo end_date: deve esistere almeno un dato nel giorno selezionato
  last_date = last_available_date(current_user.bet_point_id, @start_date, @end_date)
  if last_date.nil?
    flash[:alert] = "Nessun dato disponibile nel periodo selezionato."
    redirect_to action: :input_analyze and return
  end
  if last_date != @end_date
    flash.now[:alert] = "La data finale selezionata non contiene dati: l'analisi è stata aggiornata all'ultimo giorno disponibile (#{last_date.strftime("%d/%m/%Y")})."
    @end_date = last_date
  end

  base_scope = G1Detail.where(bet_point_id: current_user.bet_point_id)
                        .where(data: @start_date..@end_date)

  def stats_for(scope)
    total_num_emesso = scope.sum(:num_emesso)
    totals_by_tipologia = {}
    ['operatore', 'SelfService', 'SelfAdvance'].each do |tip|
      subset = scope.where(tipologia: tip)
      num_emesso = subset.sum(:num_emesso)
      percent_num_emesso = total_num_emesso > 0 ? (num_emesso.to_f / total_num_emesso * 100).round(2) : 0
      totals_by_tipologia[tip] = {
        num_emesso:  num_emesso,
        percent_num_emesso: percent_num_emesso
      }
    end
    {
      total_num_emesso: total_num_emesso,
      by_tipologia: totals_by_tipologia
    }
  end

  @datasets = [
    {
      key: 'tutti',
      title: "Tutte le giocate",
      results: stats_for(base_scope)
    },
    {
      key: 'gioco2',
      title: "Solo SPORT QF",
      results: stats_for(base_scope.where(cod_tipo_gioco: 2))
    },
    {
      key: 'gioco42',
      title: "Solo EVQF EV",
      results: stats_for(base_scope.where(cod_tipo_gioco: 42))
    }
  ]

  @media_terminals = media_terminal(base_scope, @start_date, @end_date)
  @labels = ['operatore', 'SelfService', 'SelfAdvance']

  render :res_analyze
end

def input_analyze_ter
  @start_date = Date.current.beginning_of_month
  @end_date = G1Detail.maximum(:data) 
end

def res_analyze_ter
  @start_date = params[:start_date].presence&.to_date || Date.today.beginning_of_month
  @end_date   = params[:end_date].presence&.to_date   || Date.today
  last_date = last_available_date(current_user.bet_point_id, @start_date, @end_date)
  if last_date.nil?
    flash[:alert] = "Nessun dato disponibile nel periodo selezionato."
    redirect_to action: :input_analyze_ter and return
  end
  if last_date != @end_date
    flash.now[:alert] = "La data finale selezionata non contiene dati: l'analisi è stata aggiornata all'ultimo giorno disponibile (#{last_date.strftime("%d/%m/%Y")})."
    @end_date = last_date
  end

  details = G1Detail
    .where(bet_point_id: current_user.bet_point_id)
    .where(data: @start_date..@end_date)

  @totale_num_emesso = details.sum(:num_emesso)
  @totale_impo_emesso = details.sum(:impo_emesso)

  # Raggruppa per num_term/tipologia
  grouped = details
    .select(
      :num_term,
      :tipologia,
      'SUM(num_emesso) AS totale_num_emesso',
      'SUM(impo_emesso) AS totale_impo_emesso'
    )
    .group(:num_term, :tipologia)
    .order(:num_term, :tipologia)
    .to_a

  @results = []

  grouped.each do |row|
    num_term = row.num_term
    tipologia = row.tipologia

    # 1. Riga Totale (tutti i giochi)
    totale_num_emesso = row.totale_num_emesso.to_i
    totale_impo_emesso = row.totale_impo_emesso.to_f
    percent_num_emesso = @totale_num_emesso > 0 ? (totale_num_emesso.to_f / @totale_num_emesso * 100).round(2) : 0
    percent_impo_emesso = @totale_impo_emesso > 0 ? (totale_impo_emesso / @totale_impo_emesso * 100).round(2) : 0
    @results << {
      num_term: num_term,
      tipologia: tipologia,
      gioco: "Totale",
      totale_num_emesso: totale_num_emesso,
      percent_num_emesso: percent_num_emesso,
      totale_impo_emesso: totale_impo_emesso.round(2),
      percent_impo_emesso: percent_impo_emesso
    }

    # 2. Riga SPORT
    details_sport = details.where(num_term: num_term, tipologia: tipologia, cod_tipo_gioco: 2)
    sport_num_emesso = details_sport.sum(:num_emesso)
    sport_impo_emesso = details_sport.sum(:impo_emesso)
    percent_num_emesso_sport = @totale_num_emesso > 0 ? (sport_num_emesso.to_f / @totale_num_emesso * 100).round(2) : 0
    percent_impo_emesso_sport = @totale_impo_emesso > 0 ? (sport_impo_emesso.to_f / @totale_impo_emesso * 100).round(2) : 0
    @results << {
      num_term: num_term,
      tipologia: tipologia,
      gioco: "SPORT",
      totale_num_emesso: sport_num_emesso,
      percent_num_emesso: percent_num_emesso_sport,
      totale_impo_emesso: sport_impo_emesso.round(2),
      percent_impo_emesso: percent_impo_emesso_sport
    }

    # 3. Riga VIRTUALI
    details_virtuali = details.where(num_term: num_term, tipologia: tipologia, cod_tipo_gioco: 42)
    virtuali_num_emesso = details_virtuali.sum(:num_emesso)
    virtuali_impo_emesso = details_virtuali.sum(:impo_emesso)
    percent_num_emesso_virtuali = @totale_num_emesso > 0 ? (virtuali_num_emesso.to_f / @totale_num_emesso * 100).round(2) : 0
    percent_impo_emesso_virtuali = @totale_impo_emesso > 0 ? (virtuali_impo_emesso.to_f / @totale_impo_emesso * 100).round(2) : 0
    @results << {
      num_term: num_term,
      tipologia: tipologia,
      gioco: "VIRTUALI",
      totale_num_emesso: virtuali_num_emesso,
      percent_num_emesso: percent_num_emesso_virtuali,
      totale_impo_emesso: virtuali_impo_emesso.round(2),
      percent_impo_emesso: percent_impo_emesso_virtuali
    }
  end

  # --- RIEPILOGO PER TIPOLOGIA ---
  @totali_per_tipologia = {}
  ['operatore', 'SelfService', 'SelfAdvance'].each do |tip|
    tot = details.where(tipologia: tip)
    tot_sport = tot.where(cod_tipo_gioco: 2)
    tot_virtuali = tot.where(cod_tipo_gioco: 42)
    @totali_per_tipologia[tip] = {
      totale_num_emesso: tot.sum(:num_emesso),
      totale_impo_emesso: tot.sum(:impo_emesso),
      sport_num_emesso: tot_sport.sum(:num_emesso),
      sport_impo_emesso: tot_sport.sum(:impo_emesso),
      virtuali_num_emesso: tot_virtuali.sum(:num_emesso),
      virtuali_impo_emesso: tot_virtuali.sum(:impo_emesso)
    }
  end

  # --- TOTALE GENERALE ---
  @totale_generale = {
    totale_num_emesso: @totale_num_emesso,
    totale_impo_emesso: @totale_impo_emesso,
    sport_num_emesso: details.where(cod_tipo_gioco: 2).sum(:num_emesso),
    sport_impo_emesso: details.where(cod_tipo_gioco: 2).sum(:impo_emesso),
    virtuali_num_emesso: details.where(cod_tipo_gioco: 42).sum(:num_emesso),
    virtuali_impo_emesso: details.where(cod_tipo_gioco: 42).sum(:impo_emesso)
  }

  render :res_analyze_ter
end

  private



    def media_terminal(details, start_date, end_date)
    days_count = (end_date - start_date).to_i + 1
    return {} if days_count == 0

    daily_counts = details.select(:tipologia, :data, :num_term).distinct
    terminali_per_giorno = daily_counts.group_by { |d| [d.tipologia, d.data] }
    counts_by_tipologia = Hash.new { |h, k| h[k] = [] }
    terminali_per_giorno.each do |(tip, giorno), arr|
      counts_by_tipologia[tip] << arr.map(&:num_term).uniq.count
    end

    counts_by_tipologia.transform_values do |counts|
      (counts.sum.to_f / days_count).round(2)
    end
  end

  def last_available_date(bet_point_id, start_date, end_date)
    G1Detail.where(bet_point_id: bet_point_id)
            .where('data >= ?', start_date)
            .where('data <= ?', end_date)
            .order(data: :desc)
            .limit(1)
            .pluck(:data)
            .first
  end
end