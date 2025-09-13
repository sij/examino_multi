class GetDataController < ApplicationController
  # visualizza i files csv scaricati
  def show_csv
    dest_dir = Rails.root.join('public', 'download')
    pattern = File.join(dest_dir, "*#{current_user.owner.gruppo}.csv")
    @files = Dir.glob(pattern).map { |path| [File.basename(path), File.size(path)] }
    render :res_get_g1
  end

  def in_get_g1
    # solo form, non fa nulla se GET
  end

  def res_get_g1
    from_date = params[:date_from].presence && params[:date_from].to_date
    to_date   = params[:date_to].presence && params[:date_to].to_date

    dest_dir = Rails.root.join('public', 'download')
    FileUtils.mkdir_p(dest_dir)

    @files = []

    if from_date && to_date
      (from_date..to_date).each do |date|
        giorno = date.day.to_s.rjust(2, '0')
        mese   = date.month.to_s.rjust(2, '0')
        anno   = date.year.to_s

      cmd = [
        'bash',
        Rails.root.join('script', 'bash', 'get_giornaliero.sh').to_s,
        'CSMFG1',
        current_user.owner.gruppo,
        giorno,
        mese,
        anno
      ].shelljoin

        success = system(cmd) # RUBY_SCRIPT="$APP_ROOT/script/ruby/snai_fetch.rb"
        unless success
          Rails.logger.error "get_giornaliero.sh fallito per #{date}"
          Rails.logger.error "get_giornaliero.sh fallito per #{date} — comando: #{cmd}"
        end

        # se vuoi solo i file creati ora:
        # nome_file = ... (dipende dal nome prodotto dallo script ruby)
        # @files << [nome_file, File.size(File.join(dest_dir, nome_file))]
      end
    end

    # Se vuoi comunque tutti i CSV nella cartella
    pattern = File.join(dest_dir, "*#{current_user.owner.gruppo}.csv")
    @files = Dir.glob(pattern).map { |path| [File.basename(path), File.size(path)] }

    render :res_get_g1
  end

#  require 'csv'

  def update_csv
    filename = params[:filename]
    file_path = Rails.root.join('public', 'download', filename)

    unless File.exist?(file_path)
      redirect_to in_get_g1_get_data_index_path, alert: "File non trovato."
      return
    end

    allowed = G1Detail.column_names - %w[id created_at updated_at]

    # Trova la prima data valida nel CSV
    csv_date = nil
    CSV.foreach(file_path, headers: true) do |row|
      next if row['cod_tipo_gioco'] == '0'
      csv_date = row['data']
      break
    end

    if csv_date.nil?
      redirect_to in_get_g1_get_data_index_path, alert: "CSV vuoto o dati non validi."
      return
    end

    # Se esiste almeno un record con questa data, esci subito
    if G1Detail.where(data: csv_date, owner_id: current_user.owner_id).exists?
      redirect_to root_path, alert: "CSV già importato: esistono record con data #{csv_date} per il tuo owner."
      return
    end
    # Procedi con l'importazione
    inserted = 0
    CSV.foreach(file_path, headers: true) do |row|
      next if row['cod_tipo_gioco'] == '0'
      data = row.to_h.slice(*allowed)
      csmf_cod = row['csmf_cod']
      point = Point.find_by(code: csmf_cod)
      data['bet_point_id'] = point&.bet_point_id

      # Logica SelfAdvance
      num_term = row['num_term'].to_i
      if SelfAdvance.exists?(num_term: num_term)
        data['tipologia'] = 'SelfAdvance'
      end
      # altrimenti rimane quello del CSV
      # Assegna owner_id
      data['owner_id'] = current_user.owner_id

      G1Detail.create(data)
      inserted += 1
    end

    File.delete(file_path) if File.exist?(file_path)
    redirect_to in_get_g1_get_data_path, notice: "Importati #{inserted} record da #{filename}. File cancellato."
  end

    def update_all_csv
    dest_dir = Rails.root.join('public', 'download')
    pattern = File.join(dest_dir, "*#{current_user.owner.gruppo}.csv")
    # pattern = File.join(dest_dir, '*.csv')
    files = Dir.glob(pattern)
    count = 0
    errors = []

    files.each do |file_path|
      filename = File.basename(file_path)
      allowed = G1Detail.column_names - %w[id created_at updated_at]

      # Trova la prima data valida nel CSV
      csv_date = nil
      CSV.foreach(file_path, headers: true) do |row|
        next if row['cod_tipo_gioco'] == '0'
        csv_date = row['data']
        break
      end

      if csv_date.nil?
        errors << "#{filename}: CSV vuoto o dati non validi."
        next
      end

      # Se esiste almeno un record con questa data, salta
      if G1Detail.where(data: csv_date, owner_id: current_user.owner_id).exists?
        byebug
        errors << "#{filename}: già importato."
        next
      end

      inserted = 0
      CSV.foreach(file_path, headers: true) do |row|
        next if row['cod_tipo_gioco'] == '0'
        data = row.to_h.slice(*allowed)
        csmf_cod = row['csmf_cod']
        point = Point.find_by(code: csmf_cod)
        data['bet_point_id'] = point&.bet_point_id

        # Logica SelfAdvance
        num_term = row['num_term'].to_i
        if SelfAdvance.exists?(num_term: num_term)
          data['tipologia'] = 'SelfAdvance'
        end
        # Assegna owner_id
        data['owner_id'] = current_user.owner_id

        G1Detail.create(data)
        inserted += 1
      end

      File.delete(file_path) if File.exist?(file_path)
      count += 1
    end

    msg = "Importati #{count} file."
    msg += " Errori: #{errors.join('; ')}" if errors.any?
    redirect_to in_get_g1_get_data_path, notice: msg
  end

  def delete_csv
    filename = params[:filename]
    file_path = Rails.root.join("public", "download", filename)

    if File.exist?(file_path)
      File.delete(file_path)
      redirect_to request.referer || root_path, notice: "File #{filename} eliminato con successo."
    else
      redirect_to request.referer || root_path, alert: "File non trovato."
    end
  end



end
