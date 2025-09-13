#!/usr/bin/env ruby
# encoding: UTF-8

require 'net/http'
require 'uri'
require 'json'
require 'openssl'
require 'fileutils'
require 'optparse'

# --- CONFIGURAZIONE ---
RAILS_ROOT        = '/webapp/code/prod/examino'
CREDENTIALS_PATH  = "#{RAILS_ROOT}/script/ruby/8061/credentials"
KEY_PATH          = "#{RAILS_ROOT}/script/ruby/8061/key.pem"
CERT_PATH         = "#{RAILS_ROOT}/script/ruby/8061/cert.pem"
DOWNLOAD_DIR      = "#{RAILS_ROOT}/public/download"

# --- PARAMETRI CLI ---
options = {}
OptionParser.new do |opts|
  opts.banner = "Usage: snai_fetch.rb [options]"
  opts.on("-c", "--csmf CODICE", "Codice CSMF") { |v| options[:csmf_cod] = v }
  opts.on("-t", "--tipo TIPO", "Tipo stampa") { |v| options[:tipo_stampa] = v }
  opts.on("-d", "--giorno GIORNO", "Giorno") { |v| options[:giorno] = v }
  opts.on("-m", "--mese MESE", "Mese") { |v| options[:mese] = v }
  opts.on("-y", "--anno ANNO", "Anno") { |v| options[:anno] = v }
end.parse!

[:csmf_cod, :tipo_stampa, :giorno, :mese, :anno].each do |param|
  if options[param].nil?
    puts "Parametro #{param} mancante"
    exit 1
  end
end

# --- LETTURA CREDENZIALI ---
def load_credentials
  cred_file = CREDENTIALS_PATH
  unless File.exist?(cred_file)
    puts "File credenziali non trovato: #{cred_file}"
    exit 1
  end

  content = File.read(cred_file).strip
  user, pass = content.split(',')
  if user.nil? || pass.nil?
    puts "Formato credenziali non valido in #{cred_file}. Devono esserci user,password"
    exit 1
  end

  { user: user.strip, pass: pass.strip }
end

# --- CHIAMATA API ---
def call_api(url)
  uri = URI.parse(url)
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true
  http.cert = OpenSSL::X509::Certificate.new(File.read(CERT_PATH))
  http.key = OpenSSL::PKey::RSA.new(File.read(KEY_PATH))
  http.verify_mode = OpenSSL::SSL::VERIFY_NONE
  request = Net::HTTP::Get.new(uri.request_uri)
  response = http.request(request)
  response.body
end

# --- PULIZIA RISPOSTA JSON ---
def clean_json_response(raw)
  s = raw.strip
  s = s[2..-3] if s.start_with?('("') && s.end_with?('")')
  s = s.gsub('\\"', '"')
  JSON.parse(s)
rescue JSON::ParserError => e
  puts "Errore parsing JSON VerificaStampa: #{e.message}"
  exit 1
end

# --- PULIZIA CSV DEFINITIVA ---
def clean_csv(csv_data)
  csv_data = csv_data.strip

  # Rimuove eventuali doppi apici iniziali e finali residui
  csv_data.sub!(/\A\("*/, '')
  csv_data.sub!(/\)*\z/, '')

  # Sostituisce sequenze \r\n o \r con newline reale
  csv_data.gsub!(/\\r\\n|\\r/, "\n")

  # Sostituisce \n residui con newline reale
  csv_data.gsub!(/\\n/, "\n")

  # Rimuove eventuali backslash residui
  csv_data.gsub!(/\\/, '')

  # Rimuove eventuali 'n' iniziali sulle righe dati
  csv_data.gsub!(/(?<=\n)n(?=\d)/, '')

  # Rimuove tutti gli apici
  csv_data.gsub!('"', '')

  # Rimuove righe vuote iniziali/finali e spazi indesiderati
  csv_data = csv_data.lines.map(&:strip).reject { |line| line.empty? }.join("\n")

  csv_data
end

# --- MAIN ---
def main(options)
  creds = load_credentials

  verifica_params = {
    csmf_cod: options[:csmf_cod],
    utente: creds[:user],
    password: creds[:pass],
    tipo_stampa: options[:tipo_stampa],
    giorno: options[:giorno],
    mese: options[:mese],
    anno: options[:anno],
    settimana: nil
  }

  verifica_url = "https://webcontabilita.snai.it:2443/?action=VerificaStampa&dati=#{URI.encode_www_form_component(verifica_params.to_json)}"
  puts "[VerificaStampa] URL: #{verifica_url}"
  raw_response = call_api(verifica_url)
  puts "[VerificaStampa] response: #{raw_response.inspect}"

  json = clean_json_response(raw_response)
  puts "[VerificaStampa] JSON decodificato: #{json.inspect}"

  nome_stampa = json.keys.find { |k| k.match?(/^#{options[:tipo_stampa]}/) }
  unless nome_stampa
    puts "Nessuna stampa trovata per #{options[:tipo_stampa]}"
    exit 1
  end
  puts "Nome stampa rilevata: #{nome_stampa}"

  richiedi_params = verifica_params.merge(nome_stampa: nome_stampa)
  richiedi_url = "https://webcontabilita.snai.it:2443/?action=RichiediStampa&dati=#{URI.encode_www_form_component(richiedi_params.to_json)}"
  puts "[RichiediStampa] URL: #{richiedi_url}"
  csv_data = call_api(richiedi_url)

  csv_data = clean_csv(csv_data)

  FileUtils.mkdir_p(DOWNLOAD_DIR)
  file_path = File.join(DOWNLOAD_DIR, nome_stampa)
  File.write(file_path, csv_data)
  puts "CSV salvato: #{file_path}"
end

# --- ESECUZIONE ---
main(options)
