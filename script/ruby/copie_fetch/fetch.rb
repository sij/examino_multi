require 'faraday'
require 'excon'
require 'json'
require 'csv'
require 'optparse'

#FILEPATH="./"
FILEPATH="/snai_ftp/"

class SnaiFetcher
	attr_reader :client, :code, :user, :password
	def initialize(code:)
		@code = code
		@user, @password = CSV.parse(File.read("./#{code}/credentials")).first

		@client = Faraday.new(url: 'https://webcontabilita.snai.it:2443/') do |faraday|
			faraday.request  :url_encoded
  			#faraday.response :logger
  			faraday.adapter  :excon
			faraday.ssl.verify = false
			faraday.ssl.client_cert = "./#{code}/cert.pem"
			faraday.ssl.client_key = "./#{code}/key.pem"
		end
	end
	
	def available_models
		params = {action: "ElencoStampe", dati: {"csmf_cod":"#{code}","utente":"#{user}","password":"#{password}"}.to_json}
		get(params)
	end

	def fetch_model(type: , day: nil, month: nil, year: nil, week: nil)
		params = {action: "VerificaStampa", dati: {"csmf_cod":"#{code}","utente":"#{user}","password":"#{password}", "tipo_stampa": type, "giorno": day, mese: month, anno: year, settimana: week}.to_json}
		name = get(params).keys.first
		params = {action: "RichiediStampa", dati: {"csmf_cod":"#{code}","utente":"#{user}","password":"#{password}", "tipo_stampa": type, "nome_stampa": name}.to_json}
		content = CSV.parse(get(params), headers: false)
		
		{name: name, content: content}
	end
	
	def save_model(type: , day: nil, month: nil, year: nil, week: nil, filePath: "")
		model = fetch_model(type: type, day: day, month: month, year: year, week: week)
		CSV.open("#{filePath}#{model[:name]}", "w") do |csv|
			model[:content].each do |d|
				csv << d
			end
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

options = { filePath:  FILEPATH}
code = nil #codice gruppo
OptionParser.new do |opts|
  opts.banner = "Usage: fetch.rb [options]"
	opts.on("-cCODE", "--code=CODE", "") do |n|
        code = n
	end
  	
	opts.on("-tTYPE", "--type=TYPE", "") do |n|
        options[:type] = n
	end
	
  	opts.on("-wWEEK", "--week=WEEK", "") do |n|
        options[:week] = n
	end
	
	opts.on("-dDAY", "--day=DAY", "") do |n|
        options[:day] = n
	end
	
	opts.on("-mMONTH", "--month=MONTH", "") do |n|
        options[:month] = n
	end
	
	opts.on("-yYEAR", "--year=YEAR", "") do |n|
        options[:year] = n
	end
end.parse!

SnaiFetcher.new(code: code).save_model(options)



#SnaiFetcher.new(code: code).available_models
#SnaiFetcher.new(code: 8061).save_model(type: "CSMFG1", day: "26", month: "10", year: "2018", filePath:  FILEPATH)
#SnaiFetcher.new(code: 8061).save_model(type: "CSMF_BPB",  day: "01", month: "09", year: "2018", filePath:  "bpb.csv")
#SnaiFetcher.new(code: 8061).save_model(type: "CSMF_BPB_COMP",  day: "01", month: "09", year: "2018", filePath:  "bpb_comp.csv")
#SnaiFetcher.new(code: 8061).save_model(type: "CSMFG30",  month: "09", year: "2018", filePath:  "g30.csv")
#SnaiFetcher.new(code: 8061).save_model(type: "CSMF_MOLT",  month: "09", year: "2018", filePath:  "molt.csv")
