require 'faraday'
require 'excon'
require 'json'
require 'csv'
require 'optparse'

RAILS_ROOT = "/webapp/code/prod/examino"
CREDENTIALS_PATH = "#{RAILS_ROOT}/script/ruby"
DOWNLOAD_PATH    = "#{RAILS_ROOT}/public/download/"

class SnaiFetcher
  attr_reader :client, :code, :user, :password

  def initialize(code:)
    @code = code
    cred_path = "#{CREDENTIALS_PATH}/#{code}/credentials"
    key_path  = "#{CREDENTIALS_PATH}/#{code}/key.pem"
    cert_path = "#{CREDENTIALS_PATH}/#{code}/cert.pem"
    @user, @password = CSV.parse(File.read(cred_path)).first

    @client = Faraday.new(url: 'https://webcontabilita.snai.it:2443/') do |faraday|
      faraday.request  :url_encoded
      faraday.adapter  :excon
      faraday.ssl.verify = false
      faraday.ssl.client_cert = cert_path
      faraday.ssl.client_key  = key_path
    end
  end

  def available_models
    params = { action: "ElencoStampe", dati: { "csmf_cod": code, "utente": user, "password": password }.to_json }
    get(params)
  end

  def fetch_model(type:, day: nil, month: nil, year: nil, week: nil)
    params = { action: "VerificaStampa", dati: { "csmf_cod": code, "utente": user, "password": password, "tipo_stampa": type, "giorno": day, mese: month, anno: year, settimana: week }.to_json }
    name = get(params).keys.first
    params = { action: "RichiediStampa", dati: { "csmf_cod": code, "utente": user, "password": password, "tipo_stampa": type, "nome_stampa": name }.to_json }
    content = CSV.parse(get(params), headers: false)
    { name: name, content: content }
  end

  def save_model(type:, day: nil, month: nil, year: nil, week: nil, filePath: "")
    model = fetch_model(type: type, day: day, month: month, year: year, week: week)
    CSV.open("#{filePath}#{model[:name]}", "w") do |csv|
      model[:content].each { |d| csv << d }
    end
  end

  private

  def get(params)
    req = client.get '/', params
    rsp  = JSON.load(JSON.load(req.body[1..-2]))
    if rsp.class == String
      rsp = rsp.gsub("\"", "").gsub("\r", "")
    end
    rsp
  end
end

options = { filePath: DOWNLOAD_PATH }
code = nil # codice gruppo

OptionParser.new do |opts|
  opts.banner = "Usage: fetch.rb [options]"
  opts.on("-cCODE", "--code=CODE", "") { |n| code = n }
  opts.on("-tTYPE", "--type=TYPE", "") { |n| options[:type] = n }
  opts.on("-wWEEK", "--week=WEEK", "") { |n| options[:week] = n }
  opts.on("-dDAY", "--day=DAY", "")   { |n| options[:day] = n }
  opts.on("-mMONTH", "--month=MONTH", "") { |n| options[:month] = n }
  opts.on("-yYEAR", "--year=YEAR", "") { |n| options[:year] = n }
end.parse!

SnaiFetcher.new(code: code).save_model(**options)

# Esempi:
# SnaiFetcher.new(code: code).available_models
