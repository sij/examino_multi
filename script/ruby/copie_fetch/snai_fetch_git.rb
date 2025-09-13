require 'optparse'
require 'net/https'
require 'uri'
require 'json'

begin
  require File.expand_path('../../config/environment', __dir__)
rescue LoadError
end

options = {}
OptionParser.new do |opts|
  opts.banner = "Usage: ruby snai_fetch.rb -c CSMF -t TIPO -d GIORNO -m MESE -y ANNO"
  opts.on('-c CSMF', '--csmf CSMF', 'Codice csmf') { |v| options[:csmf] = v }
  opts.on('-t TIPO', '--tipo TIPO', 'Tipo stampa (es. CSMFG1)') { |v| options[:tipo_stampa] = v }
  opts.on('-d GIORNO', '--day GIORNO', 'Giorno (es. 01)') { |v| options[:giorno] = v }
  opts.on('-m MESE', '--month MESE', 'Mese (es. 05)') { |v| options[:mese] = v }
  opts.on('-y ANNO', '--year ANNO', 'Anno (es. 2025)') { |v| options[:anno] = v }
end.parse!

base_dir = File.join(__dir__, options[:csmf])
cert_file = File.join(base_dir, 'cert.pem')
key_file  = File.join(base_dir, 'key.pem')
cred_file = File.join(base_dir, 'credentials')

if File.exist?(cred_file)
  raw = File.read(cred_file).strip
  utente, password = raw.split(',', 2).map(&:strip)
else
  abort "? File credenziali non trovato: #{cred_file}"
end

def https_get(uri_str, cert_file, key_file)
  uri = URI.parse(uri_str)
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true
  http.verify_mode = OpenSSL::SSL::VERIFY_NONE
  http.cert = OpenSSL::X509::Certificate.new(File.read(cert_file))
  http.key  = OpenSSL::PKey::RSA.new(File.read(key_file))
  request = Net::HTTP::Get.new(uri.request_uri)
  response = http.request(request)
  response.body
end

# Funzione definitiva per il "csv" SNAI, formato stringa con escape e record spezzati
def clean_snai_csv(raw)
  # 1. Togli parentesi tonde e doppi apici esterni
  clean = raw.strip
  clean = clean[1..-2] if clean.start_with?('(') && clean.end_with?(')')
  clean = clean[1..-2] if clean.start_with?('"') && clean.end_with?('"')

  # 2. Sostituisci i separatori tra record (backslash+newline) con vero newline
  clean = clean.gsub(/\\\s*\n/, "\n")

  # 3. Rimuovi escape sulle date e sulle virgolette
  clean = clean.gsub('\\/', '/').gsub('\\"', '"')

  # 4. Per ogni riga, togli virgolette esterne e splitta sui campi
  lines = clean.split("\n").map do |line|
    # Rimuovi virgolette di inizio/fine riga
    line = line.gsub(/^"+/, '').gsub(/"+$/, '')
    # Splitta i campi tra virgolette e virgola
    fields = line.split('","').map { |field| field.gsub(/^"+|"+$/, '') }
    fields.join(',')
  end

  lines.reject(&:empty?).join("\n")
end

verifica_params = {
  csmf_cod: options[:csmf],
  utente: utente,
  password: password,
  tipo_stampa: options[:tipo_stampa],
  giorno: options[:giorno],
  mese: options[:mese],
  anno: options[:anno]
}
verifica_uri = "https://webcontabilita.snai.it:2443/?action=VerificaStampa&dati=#{verifica_params.to_json}"
puts "[VerificaStampa] URL: #{verifica_uri}"
verifica_response = https_get(verifica_uri, cert_file, key_file)
puts "[VerificaStampa] response (prime 100 caratteri): #{verifica_response[0..99]}"

begin
  clean = verifica_response.strip
  clean = clean[1..-2] if clean.start_with?('(') && clean.end_with?(')')
  clean = clean[1..-2] if clean.start_with?('"') && clean.end_with?('"')
  clean = clean.gsub('\\"', '"')
  verifica_body = JSON.parse(clean)
  nome_stampa = verifica_body.keys.reject { |k| k == 'esito' }.first
  puts "Nome stampa rilevata: #{nome_stampa}"
  abort "?? Nessuna stampa disponibile" unless nome_stampa
rescue JSON::ParserError => e
  abort "? Errore parsing JSON VerificaStampa: #{e.message}"
end

richiedi_params = {
  csmf_cod: options[:csmf],
  utente: utente,
  password: password,
  tipo_stampa: options[:tipo_stampa],
  nome_stampa: nome_stampa
}
richiedi_uri = "https://webcontabilita.snai.it:2443/?action=RichiediStampa&dati=#{richiedi_params.to_json}"
puts "[RichiediStampa] URL: #{richiedi_uri}"
richiedi_response = https_get(richiedi_uri, cert_file, key_file)
puts "[RichiediStampa] response (prime 100 caratteri): #{richiedi_response[0..99]}"
puts "[RichiediStampa] response length: #{richiedi_response.length}"

if defined?(Rails)
  output_dir = Rails.root.join('public', 'download')
else
  output_dir = File.expand_path(File.join(__dir__, '..', '..', 'public', 'download'))
end

unless Dir.exist?(output_dir)
  Dir.mkdir(output_dir)
end

csv_path = File.join(output_dir, nome_stampa)
raw_path = csv_path + ".raw"
puts "[Salvataggio CSV] Path: #{csv_path}"
puts "[Salvataggio RAW] Path: #{raw_path}"

# Salva RAW
File.write(raw_path, richiedi_response)

# Salva CSV pulito (normale, senza escape)
csv_clean = clean_snai_csv(richiedi_response)
File.write(csv_path, csv_clean)
puts "? CSV pulito e RAW salvati."