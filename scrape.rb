require 'mechanize'
require 'net/http'
require 'uri'
require 'json'

def is_refreshing?
	Mechanize.new.get("https://webapps1.cityofchicago.org/StreetClosure/org/cityofchicago/streetclosure/cdot/getreport.do").body.include? "The System is refreshing"
end

def street_closure_report
	agent = Mechanize.new
	page = agent.get "https://webapps1.cityofchicago.org/StreetClosure/org/cityofchicago/streetclosure/cdot/getreport.do"
	first_row = 2
	last_row = page.search("/html/body/div[@id='mainContent']/div[@id='content']/div[@id='container']/div[@class='header']/div[@id='content-container']/center[1]/div[@id='content-panel']/center[2]/table[@class='resultTable']//tr").count
	result_table = page.search "/html/body/div[@id='mainContent']/div[@id='content']/div[@id='container']/div[@class='header']/div[@id='content-container']/center[1]/div[@id='content-panel']/center[2]/table[@class='resultTable']"
	output = { :executionTime => Time.now.inspect }

	output[:closures] = (first_row..last_row).to_a.map do |row|

		closure = {}
		from_number            = result_table.at(".//tr[#{row}]/td[1]").text.strip.gsub "\u00A0", "" # 123
		to_number              = result_table.at(".//tr[#{row}]/td[2]").text.strip.gsub "\u00A0", "" # 456
		direction              = result_table.at(".//tr[#{row}]/td[3]").text.strip.gsub "\u00A0", "" # n
		street_name            = result_table.at(".//tr[#{row}]/td[4]").text.strip.gsub "\u00A0", "" # dearborn
		street_suffix          = result_table.at(".//tr[#{row}]/td[5]").text.strip.gsub "\u00A0", "" # st
		closure[:startDate]    = result_table.at(".//tr[#{row}]/td[6]").text.strip.gsub "\u00A0", ""
		closure[:endDate]      = result_table.at(".//tr[#{row}]/td[7]").text.strip.gsub "\u00A0", ""
		closure[:closureType]  = result_table.at(".//tr[#{row}]/td[8]").text.strip.gsub "\u00A0", ""
		street                 = "#{direction} #{street_name} #{street_suffix}"
		closure[:fromAddress]  = "#{from_number} #{street}, Chicago, IL"
		closure[:toAddress]    = "#{to_number} #{street}, Chicago, IL"
		closure[:fromCoordinates] = geocode closure[:fromAddress], street_name
		closure[:toCoordinates]   = geocode closure[:toAddress], street_name

		next if closure[:fromAddress].strip.empty? || closure[:toAddress].strip.empty? || closure[:fromCoordinates].empty? || closure[:toCoordinates].empty?

		p closure

		for_a_lil_more_than_one_third_of_a_second = 0.334
		
		sleep for_a_lil_more_than_one_third_of_a_second # get around rate limiting; max 3 queries per second
		
		sleep for_a_lil_more_than_one_third_of_a_second # let's host our own pelias!
		
		closure
	end.compact
	p output.to_json
	output.to_json
end

def geocode address, street_name
	# mapzen
	# chicago_bbox = "-87.397217, 42.07436, -87.968437, 41.624851"
	# JSON.parse(Net::HTTP.get(URI.parse(URI.encode("http://pelias.mapzen.com/search?input=#{address}&bbox=#{chicago_bbox}"))))['features'].select do |closure|
	# 	closure['name'].downcase.include?(street_name.downcase) && closure['locality'].downcase == 'chicago'
	# end.first['geometry']['coordinates']

	# google
	response = JSON.parse(Net::HTTP.get(URI.parse(URI.encode("https://maps.googleapis.com/maps/api/geocode/json?address=#{address}&key=AIzaSyA1Cy1OtiZATWJvY4B251DkqmYR42L27TE"))))
	location = response['results'].first['geometry']['location']
	[location['lng'], location['lat']]
end





