require 'optparse'
require 'net/https'
require 'uri'
require 'json'

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

# Funzione per fare richieste HTTPS con certificati client
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

# Funzione per parsare correttamente il JSON incapsulato dal server
def parse_server_json(response)
  clean = response.strip
  clean = clean[1..-2] if clean.start_with?('(') && clean.end_with?(')')
  parsed = JSON.parse(clean)
  parsed = JSON.parse(parsed) if parsed.is_a?(String)
  parsed
end

# Step 1: VerificaStampa
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
puts "[VerificaStampa] response (prime 500 caratteri): #{verifica_response[0..100]}"

begin
  verifica_body = parse_server_json(verifica_response)
  nome_stampa = verifica_body.keys.reject { |k| k == 'esito' }.first
  puts "Nome stampa rilevata: #{nome_stampa}"
  abort "?? Nessuna stampa disponibile" unless nome_stampa
rescue JSON::ParserError => e
  abort "? Errore parsing JSON VerificaStampa: #{e.message}"
end

# Step 2: RichiediStampa
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
puts "[RichiediStampa] response length: #{richiedi_response.length}"
puts "[RichiediStampa] primi 500 caratteri: #{richiedi_response[0..500]}"

# Salvataggio CSV
output_dir = File.expand_path(File.join(__dir__, '..', '..', 'public', 'download'))
Dir.mkdir(output_dir) unless Dir.exist?(output_dir)
output_path = File.join(output_dir, nome_stampa)

begin
  body_csv = parse_server_json(richiedi_response)
  if body_csv[nome_stampa]
    File.write(output_path, body_csv[nome_stampa])
    puts "? CSV salvato: #{output_path}"
  else
    puts "?? Nessun CSV ricevuto: #{body_csv.inspect}"
  end
rescue JSON::ParserError => e
  puts "?? Risposta non in JSON, salvo raw: #{e.message}"
  File.write(output_path, richiedi_response)
end
