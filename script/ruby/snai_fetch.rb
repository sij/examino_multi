#!/usr/bin/env ruby
# encoding: UTF-8

require File.expand_path('../../../config/environment', __FILE__)

require 'net/http'
require 'uri'
require 'json'
require 'openssl'
require 'fileutils'
require 'optparse'
require 'logger'

# --- CONFIGURAZIONE ---
RAILS_ROOT = AppConstants::RAILS_ROOT_APP

options = {}
OptionParser.new do |opts|
  opts.banner = "Usage: snai_fetch.rb [options]"
  opts.on("-c", "--csmf CODICE", "Codice gruppo") { |v| options[:gruppo] = v }
  opts.on("-t", "--tipo TIPO", "Tipo stampa") { |v| options[:tipo_stampa] = v }
  opts.on("-d", "--giorno GIORNO", "Giorno")   { |v| options[:giorno] = v }
  opts.on("-m", "--mese MESE", "Mese")         { |v| options[:mese] = v }
  opts.on("-y", "--anno ANNO", "Anno")         { |v| options[:anno] = v }
end.parse!

# Correzione: popola csmf_cod per il webservice
options[:csmf_cod] = options[:gruppo]

# Verifica parametri necessari
[:gruppo, :tipo_stampa, :giorno, :mese, :anno].each do |param|
  if options[param].nil?
    STDERR.puts "Parametro #{param} mancante"
    exit 1
  end
end

GRUPPO = options[:gruppo]

CREDENTIALS_PATH  = "#{RAILS_ROOT}/script/ruby/#{GRUPPO}/credentials"
KEY_PATH          = "#{RAILS_ROOT}/script/ruby/#{GRUPPO}/key.pem"
CERT_PATH         = "#{RAILS_ROOT}/script/ruby/#{GRUPPO}/cert.pem"
DOWNLOAD_DIR      = "#{RAILS_ROOT}/public/download"
LOG_DIR           = "#{RAILS_ROOT}/log"
LOG_FILE          = File.join(LOG_DIR, "snai_fetch.log")

FileUtils.mkdir_p(LOG_DIR)

LOGGER = Logger.new(LOG_FILE, 'daily')
LOGGER.level = Logger::INFO   # cambia in DEBUG se vuoi log estesi

# --- LETTURA CREDENZIALI ---
def load_credentials
  cred_file = CREDENTIALS_PATH
  unless File.exist?(cred_file)
    STDERR.puts "File credenziali non trovato: #{cred_file}"
    exit 1
  end

  content = File.read(cred_file).strip
  user, pass = content.split(',')
  if user.nil? || pass.nil?
    STDERR.puts "Formato credenziali non valido in #{cred_file}. Devono esserci user,password"
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
  unless response.is_a?(Net::HTTPSuccess)
    STDERR.puts "ERRORE HTTP: #{response.code} #{response.message}"
    STDERR.puts "Body: #{response.body[0..200]}"
  end
  response.body
  # se ip non abilitato forbidden
end

# --- PULIZIA RISPOSTA JSON ---
def clean_json_response(raw)
  s = raw.strip
  s = s[2..-3] if s.start_with?('("') && s.end_with?('")')
  s = s.gsub('\\"', '"')
  JSON.parse(s)
rescue JSON::ParserError => e
  STDERR.puts "Errore parsing JSON VerificaStampa: #{e.message}"
  exit 1
end

# --- PULIZIA CSV DEFINITIVA ---
def clean_csv(csv_data)
  csv_data = csv_data.strip
  csv_data.sub!(/\A\("*/, '')
  csv_data.sub!(/\)*\z/, '')
  csv_data.gsub!(/\\r\\n|\\r/, "\n")
  csv_data.gsub!(/\\n/, "\n")
  csv_data.gsub!(/\\/, '')
  csv_data.gsub!(/(?<=\n)n(?=\d)/, '')
  csv_data.gsub!('"', '')
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
  LOGGER.info "[VerificaStampa] URL: #{verifica_url}"
  raw_response = call_api(verifica_url)
  LOGGER.debug "[VerificaStampa] response: #{raw_response.inspect}"

  json = clean_json_response(raw_response)
  LOGGER.debug "[VerificaStampa] JSON decodificato: #{json.inspect}"

  unless json.is_a?(Hash)
    STDERR.puts "Errore: risposta non valida da VerificaStampa -> #{json.inspect}"
    exit 1
  end

  nome_stampa = json.keys.find { |k| k.match?(/^#{options[:tipo_stampa]}/) }
  unless nome_stampa
    STDERR.puts "Nessuna stampa trovata per #{options[:tipo_stampa]}"
    exit 1
  end
  LOGGER.info "Nome stampa rilevata: #{nome_stampa}"

  richiedi_params = verifica_params.merge(nome_stampa: nome_stampa)
  richiedi_url = "https://webcontabilita.snai.it:2443/?action=RichiediStampa&dati=#{URI.encode_www_form_component(richiedi_params.to_json)}"
  LOGGER.info "[RichiediStampa] URL: #{richiedi_url}"
  csv_data = call_api(richiedi_url)
  LOGGER.debug "[RichiediStampa] CSV raw: #{csv_data.inspect}"

  csv_data = clean_csv(csv_data)

  FileUtils.mkdir_p(DOWNLOAD_DIR)
  file_path = File.join(DOWNLOAD_DIR, nome_stampa)
  File.write(file_path, csv_data)
  LOGGER.info "CSV salvato: #{file_path}"
end

# --- ESECUZIONE ---
main(options)